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
//        static let coordinates = "coordinates"
        static let rssi = "rssi"
        static let txPower = "txPower"
    }
    let type: ContactType
    let timestamp: Double
    let sourceNodeID: String
    let nodePairs: String
//    let lon: Double
//    let lat: Double
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
//            Keys.location: [Keys.type: "Point", Keys.coordinates: [lon, lat]],
            Keys.rssi: rssi,
            Keys.txPower: txPower ?? 0
        ]
    }
}

struct APIController {
    struct Constants {
        static let ROOT_URL = "https://api.traceph.org/api"
        static let CONTACTS_POST_URL = "\(Constants.ROOT_URL)/node_contacts"
        static let NODE_URL = "\(Constants.ROOT_URL)/node"
        static let CONTACTS_KEY = "contacts"
        static let DEVICE_ID_KEY = "device_id"
        static let DEVICE_MODEL_KEY = "device_model"
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
        let deviceModel: String = {
            let model = UIDevice.current.model
            return model
        }()
        let promise = fetchNodeID(deviceID: deviceID.uuidString, deviceModel: deviceModel)
        promise.onSucceed { nodeID in
            DefaultsKeys.myNodeID.setValue(nodeID)
        }
        return promise
    }()
    
    static func fetchNodeID(deviceID: String, deviceModel: String) -> Promise<String> {
        let promise = Promise<String>()
        Alamofire.request(
            Constants.NODE_URL,
            method: .post,
            parameters: [Constants.DEVICE_ID_KEY: deviceID, Constants.DEVICE_MODEL_KEY: deviceModel],
            encoding: JSONEncoding.default
        )
            .validate()
            .responseJSON { response in
                
                print("fetchNodeID response: \(response)")
                
                switch response.result{
                case .success(let value):
                    guard let node = JSON(value).dictionary,
                        let nodeID = node[Constants.NODE_ID_KEY]?.string else {
                            promise.reject(with: ContactsError.nonExistentNode)
                        return
                    }
                    assert(node[Constants.DEVICE_ID_KEY]?.string == deviceID, "response deviceID: \(node[Constants.DEVICE_ID_KEY]?.string ?? "") != \(deviceID)")
                    promise.resolve(with: nodeID)
                case .failure(let error):
                    promise.reject(with: error)
                }
        }
        return promise
    }
    
    func compose(items: [node_data], sourceNodeID: String) -> [[String:Any]] {
        // Includes failed posts
        var contacts = DefaultsKeys.failedContactRecordPost.dictArrayValue as? [[String:Any]] ?? [[String:Any]]()
        
        for item in items {
            guard let message = item.message else {
                    continue
            }
            
            let contact = Contact(
                type: .directBluetooth,
                timestamp: item.timestamp,
                sourceNodeID: sourceNodeID,
                nodePairs: message,
    //            lon: item.coordinates.lon,
    //            lat: item.coordinates.lat,
                rssi: item.rssi,
                txPower: item.txPower
            )
            contacts.append(contact.dict)
        }
        
        return contacts
    }
    
    // TODO: Send discoverylog array instead of one item at a time
    func send(items: [node_data], sourceNodeID: String, handler: @escaping (Result<[String]>) -> Void) {
        // TODO: Create function for multiple send that ignores ones already sent
        let contacts = compose(items: items, sourceNodeID: sourceNodeID)
            
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
                
                print("send response: \(response)")
                
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
                        
                        //REVIEW: Changed key so it works properly
                        pairedIDs.append(contentsOf: contact["node_pairs"]
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
