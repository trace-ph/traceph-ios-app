//
//  APIController.swift
//  traceph-ios-app
//
//  Created by Enzo on 07/04/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

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
        static let nodePairs = "node_pairs"
        static let location = "location"
        static let coordinates = "coordinates"
    }
    let type: ContactType
    let timestamp: Double
    let sourceNodeID: String
    let nodePairs: [String]
    let lon: Double
    let lat: Double
    
    var dict: [String:Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSSZ"
        let date = Date(timeIntervalSince1970: timestamp)
        return [
            Keys.type: type.rawValue,
            Keys.timestamp: formatter.string(from: date),
            Keys.sourceNodeID: sourceNodeID,
            Keys.nodePairs: nodePairs,
            Keys.location: [Keys.type: "Point", Keys.coordinates: [lon, lat]]
        ]
    }
}

struct APIController {
    struct Constants {
        static let CONTACTS_POST_URL = "https://api.traceph.org/api/node_contacts"
        static let CONTACTS_KEY = "contacts"
    }
    
    enum ContactsError: Error {
        case invalidNode
    }
    
    func send(item: node_data, handler: @escaping (Result<[String]>) -> Void) {
        
        // SINGLE ITEM SENDING
        // TODO: Create one for multiple send that ignores ones already sent
        guard let message = item.message else {
            handler(.failure(ContactsError.invalidNode))
            return
        }
        let deviceID = BluetoothManager.Constants.DEVICE_IDENTIFIER.uuidString
        let contact = Contact(
            type: .directBluetooth,
            timestamp: item.timestamp,
            sourceNodeID: deviceID,
            nodePairs: [message],
            lon: item.coordinates.lon,
            lat: item.coordinates.lat
        )
        var contacts = DefaultsKeys.failedContactRecordPost.dictArrayValue as? [[String:Any]] ?? [[String:Any]]()
        contacts.append(contact.dict)
        Alamofire.request(
            Constants.CONTACTS_POST_URL,
            method: .post,
            parameters: [Constants.CONTACTS_KEY: contacts],
            encoding: JSONEncoding.default
        )
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // REVIEW: This will still empty out the array even if the server responds a false positive
                    DefaultsKeys.failedContactRecordPost.setValue(nil)
                    guard let contacts = JSON(value).array else {
                        handler(.success([]))
                        return
                    }
                    var pairedIDs = [String]()
                    contacts.forEach { contact in
                        assert(contact[Contact.Keys.sourceNodeID].string == deviceID, "These contacts do not belong to this device")
                        pairedIDs.append(contentsOf: contact[Contact.Keys.nodePairs]
                            .arrayValue
                            .compactMap {$0.string} )
                    }
                    handler(.success(pairedIDs))
                case .failure(let error):
                    print("API: CONTACTS POST ERROR: \(error.localizedDescription)")
                    DefaultsKeys.failedContactRecordPost.setValue(contacts)
                    handler(.failure(error))
                }
        }
    }
}
