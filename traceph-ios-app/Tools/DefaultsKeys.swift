//
//  DefaultsKeys.swift
//  traceph-ios-app
//
//  Created by Enzo on 04/04/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

import Foundation

enum DefaultsKeys: String {
    case userHasConsented = "UDUserHasConsented"
    case failedContactRecordPost = "UDFailedContactRecordPost"
    case myNodeID = "UDMyNodeID"
    
    var boolValue: Bool {
        return UserDefaults.standard.bool(forKey: self.rawValue)
    }
    
    var stringValue: String? {
        return UserDefaults.standard.string(forKey: self.rawValue)
    }
    
    var dictArrayValue: [Any]? {
        return UserDefaults.standard.array(forKey: self.rawValue)
    }
    
    func setBool(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: self.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    func setValue(_ value: Any?) {
        UserDefaults.standard.set(value, forKey: self.rawValue)
        UserDefaults.standard.synchronize()
    }
}
