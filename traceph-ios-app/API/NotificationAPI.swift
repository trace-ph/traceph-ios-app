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
import UserNotifications


class NotificationAPI: NSObject, UNUserNotificationCenterDelegate {
    struct Constants {
        static let ROOT_URL = "https://www.detectph.com/api"
        static let NOTIF_URL = "\(Constants.ROOT_URL)/notification"
        static let CONFIRM_URL = "\(Constants.NOTIF_URL)/confirm"
        
        static let NODE_ID_KEY = "node_id"
    }
    
    func setupNotification(){
        print("Setting up notification...")
        
        NotificationCenter.default.addObserver(self, selector: #selector(exposedNotif), name: Notification.Name("Exposed"), object: nil)
        
        getNotification()
    }
    
    @objc func exposedNotif(_ notification: Notification){
        let message = notification.object as! String?
        
        let notifCenter = UNUserNotificationCenter.current()
        let notifContent = UNMutableNotificationContent()
        notifContent.title = "You have been exposed"
        notifContent.body = message!
        notifContent.sound = UNNotificationSound.default
        
        let date = Date().addingTimeInterval(1)
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let notifTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let notifUUID = UUID().uuidString
        
        let notifRequest = UNNotificationRequest(identifier: notifUUID, content: notifContent, trigger: notifTrigger)
        
        notifCenter.add(notifRequest) { (error) in
            if error != nil {
                print("Notification center add error: \(String(describing: error))")
            }
        }
    }
    
    func getNotification() {
        print("Getting notification...")
        
        APIController.sourceNodeID.onSucceed(){ nodeID in
            // Set request parameters
            var request = URLRequest(url: URL(string: Constants.NOTIF_URL)!)
            request.httpMethod = "POST"
            request.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60 // 1 minute
            request.httpBody = try! JSONSerialization.data(withJSONObject: [Constants.NODE_ID_KEY: nodeID], options: [])
            
            Alamofire.request(request as URLRequestConvertible)
            .validate()
            .responseString { [self] response in
                switch response.result {
                    case .success(let message):
//                        print(message)
                        NotificationCenter.default.post(name: Notification.Name("Exposed"), object: message)    // Show notif
                        saveNotif(message: message)
                        sendConfirmation()
                            .onSucceed(){ _ in
                                DispatchQueue.main.async {   // Update notif table
                                    NotificationViewController().reloadNotif()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: { getNotification() })   // Repoll after 1 minute
                            }
                    case .failure(_):
//                        print(err)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: { getNotification() })   // Repoll after 1 minute
                }
            }
        }
    }
    
    // Saves the received notifications
    func saveNotif(message: String){
        var notifLabel = DefaultsKeys.notifLabel.dictArrayValue as? [String] ?? [String]()
        var notifDesc = DefaultsKeys.notifDesc.dictArrayValue as? [String] ?? [String]()
        
        // Append messages
        let date = Date()
        notifLabel.append(date.getFormattedDate(format: "MMM dd, yyyy hh:mm a"))
        notifDesc.append(message)
        
        // Pop first message if more than 3 notifications
        if notifDesc.count > 3 {
            notifLabel.removeFirst()
            notifDesc.removeFirst()
        }
        
        // Save to DefaultKeys
        DefaultsKeys.notifLabel.setValue(notifLabel)
        DefaultsKeys.notifDesc.setValue(notifDesc)
    }
    
    // Sends confirmation to server that notification is received
    func sendConfirmation() -> Promise<Bool> {
        let promise = Promise<Bool>()
        
        APIController.sourceNodeID.onSucceed(){ nodeID in
            Alamofire.request(
                Constants.CONFIRM_URL,
                method: .post,
                parameters: [Constants.NODE_ID_KEY: nodeID],
                encoding: JSONEncoding.default
            ).validate()
            .responseString { response in
                switch response.result {
                case .success(_):
                        print("Exposed notification confirmed")
                        promise.resolve(with: true)
                    case .failure(let err):
                        print(err)
                        promise.reject(with: err)
                }
            }
        }
        
        return promise
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}
