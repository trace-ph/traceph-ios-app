//
//  AppDelegate.swift
//  traceph-ios-app
//
//  Created by Asti Lagmay on 3/29/20.
//  Copyright © 2020 traceph. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if let nodeID = DefaultsKeys.myNodeID.stringValue,
            (DefaultsKeys.failedContactRecordPost.dictArrayValue?.count ?? 0) > 0 {
            //enable background fetch
            application.setMinimumBackgroundFetchInterval(
                UIApplication.backgroundFetchIntervalMinimum
            )
            // send failed requests
            APIController().send(
                items: [],
                sourceNodeID: nodeID
            ) { _ in }
            
        } else {
            //disable background fetch
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        }
        
        registerLocalNotif()
        
        return true
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("DetectPH entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("DetectPH entered foreground")
    }
    
    
    func registerLocalNotif() {
        if #available(iOS 10.0, *) {
            let notifCenter = UNUserNotificationCenter.current()
            
            notifCenter.requestAuthorization(options: [.alert, .sound]) {
                [weak self] (granted, error) in
                
                if let error = error {
                    print("Notification center request error: \(String(describing: error))")
                }
                if granted {
                    print("Notifications authorized")
                }
                else {
                    print("Notifications not authorized")
                    self?.getNotificationSettings()
                }
            }
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    // To get ios notifications settings of the user
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings {
            settings in print("Notification settings  \(settings)")
            
            guard settings.authorizationStatus == .authorized else {return}
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    
    
    
    // MARK: UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void) {
        guard let nodeID = DefaultsKeys.myNodeID.stringValue else {
            completionHandler(.failed)
            return
        }
        APIController().send(items: [], sourceNodeID: nodeID) { result in
            switch result {
            case .success(let pairdIDs):
                completionHandler(pairdIDs.count == 0 ? .noData : .newData)
            case .failure(_):
                completionHandler(.failed)
            }
        }
    }
    
    // Prints device token ID
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map {
            data in String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
//        self.forwardTokenToServer(tokenString: token)
    }

    
    // Local notifications
    private func application(_ application: UIApplication,
                             didReceive notification: UNNotificationRequest) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
