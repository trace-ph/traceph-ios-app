//
//  Node.swift
//  traceph-ios-app
//
//  Created by Enzo on 30/03/2020.
//  Copyright © 2020 traceph. All rights reserved.
//
import Foundation

struct node_data {
    let name: String
    let rssi: NSNumber
    let txPower: NSNumber
    let timestamp: Double
    let deviceIdentifier: String
    let peripheralIdentifier: UUID
    let coordinates: SimpleCoordinates
    let message: String? // maybe convert to a bool `didConnect`
    
    func dateString(formatter: DateFormatter) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return formatter.string(from: date)
    }
    
    func newWithMessage(_ message: String?) -> node_data {
        return node_data(
            name: name,
            rssi: rssi,
            txPower: txPower,
            timestamp: timestamp,
            deviceIdentifier: deviceIdentifier,
            peripheralIdentifier: peripheralIdentifier,
            coordinates: coordinates,
            message: message)
    }
}
