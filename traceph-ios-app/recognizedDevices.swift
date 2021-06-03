//
//  recognizedDevices.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 6/3/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import Foundation

struct device_data {
    let peripheralIdentifier: UUID
    let node_id: String? // maybe convert to a bool `didConnect`
    
    func newWithID(_ node_id: String?) -> device_data {
        return device_data(
            peripheralIdentifier: peripheralIdentifier,
            node_id: node_id)
    }
}
