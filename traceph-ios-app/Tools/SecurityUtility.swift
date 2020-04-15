//
//  SecurityUtility.swift
//  traceph-ios-app
//
//  Created by Enzo on 15/04/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

/*
1. Turn payload to md5 (json string or "" if body is empty)
2. Create request date (timestamp with UTC format)
3. Combine this strings => method (e.g. 'post', 'get', 'put'), md5 from step 1, date and path into one string concatenated by "\n" => then hex digest
4. Sign result of step 3 using sha1_hmac and the secret => then base64 digest
5. Add the following header in the request
    {
      "Authorization: TRACE-PH {PLATFORM*}:{Signed base64 string from step 4}"
      "Date": {timestamp from step 2}
      // other headers...
      }

* PLATFORM = IOS or ADR
* Each platform has different secret, store this securely
    
The result should equal the authorization signature calculated in the backend
*/

struct SecurityUtility {
    func jsonString(from contacts: [[String:Any]]) -> String? {
        guard let jsonData = try? JSONSerialization.data(
          withJSONObject: contacts,
          options: .fragmentsAllowed) else {
            return nil
        }
        return String(
            data: jsonData,
            encoding: String.Encoding.ascii
        )
    }
    
    func MD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                    let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
}
