//
//  IntroViewController.swift
//  traceph-ios-app
//
//  Created by Enzo on 04/04/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol AdvertismentWaiter: AnyObject {
    var bluetoothManager: BluetoothManager? { get set }
    func bluetoothManager(_ manager: BluetoothManager, didStartAdvertising: Bool)
}

class IntroViewController: UIViewController {
    var bluetoothManager: BluetoothManager?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func agreeAction(_ sender: UIButton?) {
        // Should not push through if nodeID could not be get
        APIController.sourceNodeID.onFail {_ in
            let regErr = UIAlertController(title: "Register Error", message: "Could not register your device. Please check your internet connection and restart the app", preferredStyle: .alert)
            self.present(regErr, animated: true, completion: nil)
            return;
        }
        
        // Checks if the Bluetooth permissions is OK + turned on
        bluetoothManager?.waiterDelegate = self
        switch bluetoothManager?.centralManager.state {
            case .unsupported, .unauthorized, .poweredOff, .none:
                let alert = UIAlertController(title: "Bluetooth Disabled", message: "Bluetooth is required", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                    UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                
            case .resetting, .poweredOn:
                proceed()
                
            default:
                bluetoothManager?.restart()
        }
    }
    
    func proceed() {
        DefaultsKeys.userHasConsented.setBool(true)
        dismiss(animated: true, completion: nil)
    }
}

extension IntroViewController: AdvertismentWaiter {
    func bluetoothManager(_ manager: BluetoothManager, didStartAdvertising: Bool) {
        proceed()
    }
}
