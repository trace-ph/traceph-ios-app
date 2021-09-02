//
//  ReportAPI.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 8/30/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


struct ReportAPI {
    struct Constants {
        static let ROOT_URL = "https://www.detectph.com/api"
        static let REPORT_URL = "\(Constants.ROOT_URL)/report"
        static let AUTH_URL = "\(Constants.REPORT_URL)/auth"
        
        static let NODE_ID_KEY = "node_id"
        static let QRCODE_KEY = "data"
        static let AUTH_CODE_KEY = "token"
        static let PATIENT_INFO_KEY = "patient_info"
        static let TEST_RESULT_KEY = "test_result"
        static let TEST_RESULT_DATE_KEY = "test_result_date"
        static let REFERENCE_DATE_KEY = "reference_date"
    }
    
    struct patient_info {
        let test_result: Bool           // COVID result
        let test_result_date: Date      // Date when results were recieved
        let reference_date: Date        // Date of testing
    }
    
    
    // Sends QR data to the server and get corresponding auth code
    func getToken(nodeID: String, data: String) -> Promise<String> {
        let promise = Promise<String>()
        
        Alamofire.request(
            Constants.AUTH_URL,
            method: .get,
            parameters: [Constants.NODE_ID_KEY: nodeID, Constants.QRCODE_KEY: data]
        )
        .validate()
        .responseJSON { response in
            switch response.result {
                case .success(let value):
                    print("Auth code: \(value)")
                    promise.resolve(with: "\(value)")
                case .failure(let err):
                    print(err)
                    promise.reject(with: err)
            }
        }
        
        return promise
    }
    
    // Confirm inputted auth code to server and receive report verdict
    func sendReport(nodeID: String, authCode: String, data: String, info: patient_info) -> Promise<String> {
        let promise = Promise<String>()
        
        // Format the parameters
        let resDate = info.test_result_date.getFormattedDate(format: "yyyy-MM-dd")
        let refDate = info.reference_date.getFormattedDate(format: "yyyy-MM-dd")
        print(info.test_result_date, resDate)
        print(info.reference_date, refDate)
        let parameters: [String: Any] = [
            Constants.NODE_ID_KEY: nodeID,
            Constants.QRCODE_KEY: data,
            Constants.AUTH_CODE_KEY: authCode,
            Constants.PATIENT_INFO_KEY: [
                Constants.TEST_RESULT_KEY: info.test_result,
                Constants.TEST_RESULT_DATE_KEY: resDate,
                Constants.REFERENCE_DATE_KEY: refDate]
        ]
        
        // Send to server
        Alamofire.request(
            Constants.REPORT_URL,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .responseString { response in
            switch response.result {
                case .success(let verdict):
                    print(verdict)
                    promise.resolve(with: "\(verdict)")
                case .failure(let err):
                    print(err)
                    promise.reject(with: err)
            }
        }
        
        return promise
    }
}
