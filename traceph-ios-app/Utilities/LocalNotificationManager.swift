//
//  LocalNotificationManager.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 10/7/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import Foundation
import UserNotifications

struct LocalNotification {
    var id: String
    var title: String
    var body: String
    var datetime: DateComponents
    var repeats: Bool
}

class LocalNotificationManager {
    var notifications = [LocalNotification]()
    
    // For debugging purposes; Lists down what are the scheduled notifs are
    func listScheduledNotification(){
        UNUserNotificationCenter.current().getPendingNotificationRequests { notifications in
            for notification in notifications {
                print(notification)
            }
        }
    }
    
    private func requestAuthorization(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted == true && error == nil {
                self.scheduleNotification()
            }
        }
    }
    
    func schedule(){
        UNUserNotificationCenter.current().getNotificationSettings { [self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                requestAuthorization()
            case .authorized, .provisional:
                scheduleNotification()
            default:
                break // Do nothing
            }
        }
    }
    
    private func scheduleNotification() {
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: notification.datetime, repeats: notification.repeats)
            
            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request){ error in
                guard error == nil else {
                    print("Notification center add error: \(String(describing: error))")
                    return
                }
                
                print("Notification scheduled! --- ID = \(notification.id)")
            }
        }
    }
    
    func removeNotification(requestIdentifier: [String]){
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: requestIdentifier)
    }
}
