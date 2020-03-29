//
//  Utility.swift
//  traceph-ios-app
//
//  Created by Enzo on 29/03/2020.
//  Copyright © 2020 traceph. All rights reserved.
//
import UIKit

struct Utility {
    static func getDeviceIdentifier() -> String {
        assert(UIDevice.current.identifierForVendor?.uuidString != nil, "identifier must exist")
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
