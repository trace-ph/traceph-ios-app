//
//  ViewController.swift
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

protocol ViewControllerInputs {
    func reloadTable(indexPath: IndexPath?)
    func setPeripheral(status: String?)
    func waitForAdvertisment()
}

enum DeviceLockState {
    case locked
    case unlocked
}

class ViewUtility {
    class func checkLockState(completion: @escaping (DeviceLockState) -> Void) {
        DispatchQueue.main.async {
            if (UIApplication.shared.isProtectedDataAvailable) {
                completion(.unlocked)
            } else {
                completion(.locked)
            }
        }
    }
}


class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    struct Constants {
        static let REUSE_IDENTIFIER = "discoveredNodeCell"
    }
    
    enum Segues: String {
        case intro = "intro"
        case authorize = "authorize"

        func perform(controller: UIViewController, sender: Any?) {
            controller.performSegue(withIdentifier: self.rawValue, sender: sender)
        }
    }
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    var bluetoothManager: BluetoothManager!
    
    @IBOutlet weak var debugView: UIView?
    @IBOutlet weak var shareView: UIView?
    @IBOutlet weak var shareTextView: UITextView?
    @IBOutlet weak var detectButton: UIButton?
    @IBOutlet weak var deviceTable: UITableView?
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var contactTracingLabel: UILabel?
    @IBOutlet weak var contactTracingSwitch: UISwitch?
    
    
    var isLowPower = false
    @IBOutlet weak var lowPowerButton: UIButton!
    
    @IBAction func lowPowerPress(_ sender: Any) {
        
        if !isLowPower {
            self.view.backgroundColor = UIColor.black
            
            headerImage.isHidden = true
            shareTextView?.isHidden = true
            contactTracingLabel?.isHidden = true
            contactTracingSwitch?.isHidden = true
            navigationController?.isNavigationBarHidden = true
            
            lowPowerButton.setTitle("TURN OFF", for: .normal)
            lowPowerButton.backgroundColor = UIColor.black
            
            isLowPower = true
        }
        
        else {
            self.view.backgroundColor = UIColor.white
            
            headerImage.isHidden = false
            shareTextView?.isHidden = false
            contactTracingLabel?.isHidden = false
            contactTracingSwitch?.isHidden = false
            navigationController?.isNavigationBarHidden = false
            
            lowPowerButton.setTitle("LOW-POWER MODE", for: .normal)
            lowPowerButton.backgroundColor = UIColor.systemGreen
            
            isLowPower = false
            
        }
        
    }

    let appProcessingTaskId = "com.detectph.ios"
    var toggleDetect = false
    var backgroundTaskID: UIBackgroundTaskIdentifier!
    
    @IBAction func detectPress(_ sender: UIButton?) {
        toggleDetect = !toggleDetect
        
        
        
        if(toggleDetect) {
            bluetoothManager.detect()
            detectButton?.setTitle("Disable Contact-tracing", for: .normal)
        } else {
            bluetoothManager.stop()
            detectButton?.setTitle("Enable Contact-tracing", for: .normal)
        }
        
    }
    
    @available(iOS 13.0, *)
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: appProcessingTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30) // Refresh after __ minute.
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Submitted")
        } catch {
            print("Could not schedule app refresh task \(error.localizedDescription)")
        }
    }
    
    func showPhoneState(_ deviceLockState: DeviceLockState) {
        let date = Date().addingTimeInterval(3)
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let notifManager = LocalNotificationManager()
        
        switch deviceLockState {
            case .locked:
                print("State: Locked")
                print("BG Close")
                notifManager.notifications.append(LocalNotification(
                    id: "Wake up Notif",
                    title: "Gising! Gising!",
                    body: "Test iOS Message Background Close",
                    datetime: dateComponents,
                    repeats: true
                ))
            case .unlocked:
                print("State: Unlocked")
        }
        notifManager.schedule()
    }
    
    
    @IBAction func toggleContact(_ sender: UISwitch) {
        if sender.isOn {
            bluetoothManager.detect()
        } else {
            bluetoothManager.stop()
        }
        
        // Trigger notification behavior
        NotificationCenter.default.post(name: Notification.Name("isContactTracing"), object: sender.isOn)
    }
    
    // Shows/Removes notification that the app is creating records of contacts
    @objc func isContactTracing(_ notification: Notification){
        let isOn = notification.object as! Bool
        let notifManager = LocalNotificationManager()
        
        if isOn {
            let date = Date().addingTimeInterval(1)
            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            
            notifManager.notifications.append(LocalNotification(
                id: "is.contact.tracing",
                title: "Recording contacts...",
                body: "DetectPH is creating records of your contacts",
                datetime: dateComponents,
                repeats: false
            ))
            notifManager.schedule()
        
        } else {
            notifManager.removeNotification(requestIdentifier: ["is.contact.tracing"])
        }
    }
    
    
    func updateTextFont(textView: UITextView) {
        if (textView.text.isEmpty || textView.bounds.size.equalTo(CGSize.zero)) {
            return;
        }
        
        let textViewSize = textView.frame.size;
        let fixedWidth = textViewSize.width;
        let expectSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        
        var expectFont = textView.font;
        if (expectSize.height > textViewSize.height) {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height) {
                expectFont = textView.font!.withSize(textView.font!.pointSize - 1)
                textView.font = expectFont
            }
        }
        else {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height) {
                expectFont = textView.font;
                textView.font = textView.font!.withSize(textView.font!.pointSize + 1)
            }
            textView.font = expectFont;
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bluetoothManager = BluetoothManager(inputs: self)
//        #if DEBUG
//        shareView = nil
//        view = debugView
//        #else
        debugView = nil
        view = shareView
        //        shareTextView?.translatesAutoresizingMaskIntoConstraints = true
        shareTextView?.sizeToFit()
        shareTextView?.isScrollEnabled = false
        //        qrTextView?.translatesAutoresizingMaskIntoConstraints = true
//        #endif
        
        let backgroundNotifCenter = NotificationCenter.default
        backgroundNotifCenter.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.willResignActiveNotification, object: nil)
        backgroundNotifCenter.addObserver(self, selector: #selector(isContactTracing), name: Notification.Name("isContactTracing"), object: nil)
        
        // Call notification function
//        NotificationAPI().setupNotification()
        
    }
    
    @objc func didEnterBackground() {
        print("VW App entered background")
        let notifManager = LocalNotificationManager()
        let date = Date().addingTimeInterval(3)
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        
        if #available(iOS 13, *) {
            self.scheduleAppRefresh()
        }

        // FALSE if device is locked
        //      Reference: https://nemecek.be/blog/104/checking-if-device-is-locked-or-sleeping-in-ios
//        if(UIApplication.shared.isProtectedDataAvailable) {
            notifManager.notifications.append(LocalNotification(
                id: "BG notif",
                title: "DetectPH is running in the background",
                body: "Please keep DetectPH running to detect devices properly",
                datetime: dateComponents,
                repeats: false
            ))
//        } else {
//            notifManager.notifications.append(LocalNotification(
//                id: "WakeUpNotif",
//                title: "Gising! Gising!",
//                body: "Test iOS Message",
//                datetime: Calendar.current.dateComponents(
//                    [.year, .month, .day, .hour, .minute, .second],
//                    from: Date().addingTimeInterval(1)),
//                repeats: true
//            ))
//        }
            
        notifManager.schedule()
        print("A")
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask()
        print(backgroundTaskID.rawValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            print("B")
            ViewUtility.checkLockState() { lockState in
                if let self = self {
                    self.showPhoneState(lockState)
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                    print("out")
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkForModals()
    }
    
    func checkForModals() {
        if !DefaultsKeys.userHasConsented.boolValue {
            Segues.intro.perform(controller: self, sender: nil)
        } else if bluetoothManager.centralManager.state != .poweredOn {
            waitForAdvertisment()
        } else {
            bluetoothManager.detect()
        }
    }
    
    func waitForAdvertisment() {
        guard presentedViewController == nil else {
            return
        }
        print("presenting waiter")
        Segues.authorize.perform(controller: self, sender: nil)
    }
    
    
    @IBOutlet weak var peripheralStatus: UILabel!
    @IBOutlet weak var deviceProfile: UILabel!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? AdvertismentWaiter else {
            return
        }
        controller.bluetoothManager = self.bluetoothManager
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

extension ViewController: ViewControllerInputs {
    func reloadTable(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            deviceTable?.reloadRows(at: [indexPath], with: .automatic)
        } else {
            deviceTable?.reloadData()
        }
    }
    
    var controller: ViewController {
        return self
    }
    func setDetectButton(enabled: Bool) {
        detectButton?.isEnabled = enabled
        detectButton?.alpha = enabled ? 1 : 0.5
        if !enabled {
            waitForAdvertisment()
        }
    }
    
    func reloadTable() {
        deviceTable?.reloadData()
    }
    
    func setPeripheral(status: String?) {
        peripheralStatus.text = status
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothManager.discoveryLog.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIER) else {
            assertionFailure("Register \(Constants.REUSE_IDENTIFIER) cell first")
            return UITableViewCell()
        }
        
        let node = bluetoothManager.discoveryLog[indexPath.row]
        if let message = node.message {
            cell.textLabel?.text = "\(node.name)\t-\t\(message)"
        } else {
            cell.textLabel?.text = node.name
        }
//        let coordinates = bluetoothManager.locationService.currentCoords
//        let currentLat = String(format: "%.6f", coordinates.lat)
//        let currentLon = String(format: "%.6f", coordinates.lon)
        
        //REVIEW: Create UITableViewCell depending on needed information
//        cell.detailTextLabel?.text = "\(node.rssi)\t-\t\(node.dateString(formatter: dateFormatter))\t-\t[\(currentLat), \(currentLon)]"
        cell.detailTextLabel?.text = "\(node.rssi)\t-\t\(node.dateString(formatter: dateFormatter))\t"
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UITextView {
    func decreaseFontSize () {
        self.font =  UIFont(name: self.font!.fontName, size: self.font!.pointSize-1)!
    }
}
