//
//  SceneDelegate.swift
//  traceph-ios-app
//
//  Created by Asti Lagmay on 3/29/20.
//  Copyright © 2020 traceph. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation
import BackgroundTasks
import UserNotifications


//enum DeviceLockState {
//    case locked
//    case unlocked
//}
//
//class ViewUtility {
//    class func checkLockState(completion: @escaping (DeviceLockState) -> Void) {
//        DispatchQueue.main.async {
//            if (UIApplication.shared.isProtectedDataAvailable) {
//                completion(.unlocked)
//            } else {
//                completion(.locked)
//            }
//        }
//    }
//}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
//    var backgroundTaskID: UIBackgroundTaskIdentifier!
    var bluetoothManager: BluetoothManager!
//    var viewControl: ViewController
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // MARK: Schedule Background Tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "DetectPH.BGRefresh", using: nil) {
            task in

            print("BG Refresh Task Registered")
            task.setTaskCompleted(success: true)
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "DetectPH.BGProcess", using: nil) {
            task in

            print("BG processing Task Registered")
            task.setTaskCompleted(success: true)
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
        }
    }

    @available(iOS 13.0, *)
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("Scene will enter foreground.")
    }

    @available(iOS 13.0, *)
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print("Scene did enter background.")
        scheduleAppRefresh()
        scheduleAppProcessing()
    }
    
    @available(iOS 13.0, *)
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "DetectPH.BGRefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled.")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    @available(iOS 13.0, *)
    func scheduleAppProcessing() {
        let request = BGProcessingTaskRequest(identifier: "DetectPH.BGProcess")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled.")
            //bluetoothManager.detect()
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    @available(iOS 13.0, *)
    func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        print("\tA.")
        
        let notifManager = LocalNotificationManager()
        let date = Date()
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        notifManager.notifications.append(
            LocalNotification(
                id: "Wake up Notif",
                title: "Gising! Gising!",
                body: "Test iOS Message Background Close",
                datetime: dateComponents,
                repeats: true
            )
        )
        notifManager.schedule()
        print("\tNotif time: \(dateComponents)")
    }
    
    
    @available(iOS 13.0, *)
    func handleBackgroundProcessing(task: BGProcessingTask) {
        scheduleAppProcessing()
        print("\tB.")
        
        let notifManager = LocalNotificationManager()
        let date = Date()
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        notifManager.notifications.append(
            LocalNotification(
                id: "Wake up Notif",
                title: "Gising! Gising!",
                body: "Test iOS Message Background Close",
                datetime: dateComponents,
                repeats: true
            )
        )
        notifManager.schedule()
        print("\tNotif time: \(dateComponents)")
    }
    
    
    
    func showPhoneState() {
        let notifManager = LocalNotificationManager()
        let date = Date()
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )

        bluetoothManager.detect()
        notifManager.notifications.append(
            LocalNotification(
                id: "Wake up Notif",
                title: "Gising! Gising!",
                body: "Test iOS Message Background Close",
                datetime: dateComponents,
                repeats: true
            )
        )

        notifManager.schedule()
        print("\tNotif time: \(dateComponents)")

//        switch deviceLockState {
//            case .locked:
//                print("State: Locked")
//                print("BG CLOSE")
//                bluetoothManager.detect()
//                notifManager.notifications.append(
//                    LocalNotification(
//                        id: "Wake up Notif",
//                        title: "Gising! Gising!",
//                        body: "Test iOS Message Background Close",
//                        datetime: dateComponents,
//                        repeats: true
//                    )
//                )
//                print("\tNotif time: \(dateComponents)")
//
//            case .unlocked:
//                print("State: Unlocked")
//                print("BG OPEN")
//                bluetoothManager.detect()
//                notifManager.notifications.append(
//                    LocalNotification(
//                        id: "Wake up Notif",
//                        title: "Gising! Gising!",
//                        body: "Test iOS Message Background Open",
//                        datetime: dateComponents,
//                        repeats: true
//                    )
//                )
//                print("\tNotif time: \(dateComponents)")
//        }
    }
}

