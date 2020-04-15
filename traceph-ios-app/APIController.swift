//
//  APIController.swift
//  traceph-ios-app
//
//  Created by Enzo on 07/04/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum ContactType: String {
    case directBluetooth = "direct-bluetooth"
    case directNetwork = "direct-network"
    case indirect = "indirect"
    case manual = "manual"
}

struct Contact {
    struct Keys {
        static let type = "type"
        static let timestamp = "timestamp"
        static let sourceNodeID = "source_node_id"
        static let nodePair = "node_pair"
        static let location = "location"
        static let coordinates = "coordinates"
        static let rssi = "rssi"
        static let txPower = "txPower"
    }
    let type: ContactType
    let timestamp: Double
    let sourceNodeID: String
    let nodePairs: [String]
    let lon: Double
    let lat: Double
    let rssi: NSNumber
    let txPower: NSNumber?
    
    var dict: [String:Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSSZ"
        let date = Date(timeIntervalSince1970: timestamp)
        return [
            Keys.type: type.rawValue,
            Keys.timestamp: formatter.string(from: date),
            Keys.sourceNodeID: sourceNodeID,
            Keys.nodePair: nodePairs,
            Keys.location: [Keys.type: "Point", Keys.coordinates: [lon, lat]],
            Keys.rssi: rssi,
            Keys.txPower: txPower ?? 0
        ]
    }
}

struct APIController {
    struct Constants {
        static let CONTACTS_POST_URL = "https://api.traceph.org/api/node_contacts"
        static let NODE_URL = "https://api.traceph.org/api/node"
        static let CONTACTS_KEY = "contacts"
        static let DEVICE_ID_KEY = "device_id"
        static let NODE_ID_KEY = "node_id"
    }
    
    enum ContactsError: Error {
        case invalidNode
        case nonExistentNode
    }
    
    static let sourceNodeID: Promise<String> = {
        if let existing = DefaultsKeys.myNodeID.stringValue {
            return Promise<String>.init(value: existing)
        }
        let deviceID: UUID = {
            let identifier = UIDevice.current.identifierForVendor
            assert(identifier != nil, "Device Identifier must exist")
            return identifier ?? UUID()
        }()
        let promise = fetchNodeID(deviceID: deviceID.uuidString)
        promise.observe { result in
            guard case .success(let value) = result else {
                return
            }
            DefaultsKeys.myNodeID.setValue(value)
        }
        return promise
    }()
    
    static func fetchNodeID(deviceID: String) -> Promise<String> {
        let promise = Promise<String>()
        Alamofire.request(
            Constants.NODE_URL,
            method: .post,
            parameters: [Constants.DEVICE_ID_KEY: deviceID],
            encoding: JSONEncoding.default
        )
            .validate()
            .responseJSON { response in
                switch response.result{
                case .success(let value):
                    guard let node = JSON(value).dictionary,
                        let nodeID = node[Constants.NODE_ID_KEY]?.string else {
                            promise.reject(with: ContactsError.nonExistentNode)
                        return
                    }
                    promise.resolve(with: nodeID)
                case .failure(let error):
                    promise.reject(with: error)
                }
        }
        return promise
    }
    
    func compose(item: node_data?, sourceNodeID: String) -> [[String:Any]] {
        // Includes failed posts
        var contacts = DefaultsKeys.failedContactRecordPost.dictArrayValue as? [[String:Any]] ?? [[String:Any]]()
        
        guard let item = item,
            let message = item.message else {
                return contacts
        }
        guard UUID(uuidString: message) != nil else {
            // TODO: Turn this into an assertion
            print("\(message) should be a UUID")
            return contacts
        }
        let contact = Contact(
            type: .directBluetooth,
            timestamp: item.timestamp,
            sourceNodeID: sourceNodeID,
            nodePairs: [message],
            lon: item.coordinates.lon,
            lat: item.coordinates.lat,
            rssi: item.rssi,
            txPower: item.txPower
        )
        contacts.append(contact.dict)
        return contacts
    }
    
    func send(item: node_data?, sourceNodeID: String, handler: @escaping (Result<[String]>) -> Void) {
        // TODO: Create function for multiple send that ignores ones already sent
        let contacts = compose(item: item, sourceNodeID: sourceNodeID)
        guard contacts.count > 0 else {
            handler(.failure(ContactsError.invalidNode))
            return
        }
        Alamofire.request(
            Constants.CONTACTS_POST_URL,
            method: .post,
            parameters: [Constants.CONTACTS_KEY: contacts],
            encoding: JSONEncoding.default
        )
//            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // REVIEW: This will still empty out the array even if the server responds a false positive
                    DefaultsKeys.failedContactRecordPost.setValue(nil)
                    //disable background fetch
                    UIApplication.shared
                    .setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
                    guard let contacts = JSON(value).array else {
                        print(value)
                        handler(.success([]))
                        return
                    }
                    var pairedIDs = [String]()
                    contacts.forEach { contact in
                        assert(contact[Contact.Keys.sourceNodeID].string == sourceNodeID, "These contacts do not belong to this device")
                        pairedIDs.append(contentsOf: contact[Contact.Keys.nodePair]
                            .arrayValue
                            .compactMap {$0.string} )
                    }
                    handler(.success(pairedIDs))
                case .failure(let error):
                    //enable background fetch
                    UIApplication.shared
                    .setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
                    print("API: CONTACTS POST ERROR: \(error.localizedDescription)")
                    DefaultsKeys.failedContactRecordPost.setValue(contacts)
                    handler(.failure(error))
                }
        }
    }
}
