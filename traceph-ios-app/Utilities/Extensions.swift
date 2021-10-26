//
//  Extensions.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 9/1/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import Foundation

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}
