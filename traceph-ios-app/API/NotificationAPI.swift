//
//  NotificationAPI.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 9/1/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


struct NotificationAPI {
    struct Constants {
        static let ROOT_URL = "https://www.detectph.com/api"
        static let REPORT_URL = "\(Constants.ROOT_URL)/notif"
        
        static let NODE_ID_KEY = "node_id"
    }
}
