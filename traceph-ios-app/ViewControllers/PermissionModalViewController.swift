//
//  PermissionModalViewController.swift
//  traceph-ios-app
//
//  Created by Enzo on 04/04/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

import UIKit
import CoreBluetooth

class PermissionModalViewController: UIViewController {

    var bluetoothManager: BluetoothManager? {
        didSet {
            assert(bluetoothManager?.centralManager.state != .poweredOn || bluetoothManager?.peripheralManager.state != .poweredOn, "only load this view if state is not powered on")
            bluetoothManager?.waiterDelegate = self
            bluetoothManager?.restart()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func agreeAction(_ sender: UIButton?) {
        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    func proceed() {
        dismiss(animated: true, completion: nil)
    }
}

extension PermissionModalViewController: AdvertismentWaiter {
    func bluetoothManager(_ manager: BluetoothManager, didStartAdvertising: Bool) {
        guard didStartAdvertising else {
            return
        }
        proceed()
    }
}
