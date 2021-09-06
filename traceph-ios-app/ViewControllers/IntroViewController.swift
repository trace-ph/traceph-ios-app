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
    struct Constants {
        static let privacy = "https://www.detectph.com/privacy.html"
    }
    
    var bluetoothManager: BluetoothManager?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func privPolicyLink(){
        UIApplication.shared.open(URL(string: Constants.privacy)!)
    }
    
    @IBOutlet weak var checkBox: UIButton?
    @IBAction func toggleCheckBox(_ sender: UIButton){
        checkBox?.isSelected = !checkBox!.isSelected
    }
    
    @IBAction func agreeAction(_ sender: UIButton?) {
        // Make sure that the privacy policy is read (AKA checkbox is checked)
        if checkBox?.isSelected == false {
            let checkBoxAlert = UIAlertController(title: "Privacy policy", message: "You have to read the privacy policy to continue.", preferredStyle: .alert)
            checkBoxAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(checkBoxAlert, animated: true, completion: nil)
            return
        }
        
        // Should not push through if nodeID could not be get
        APIController.sourceNodeID.onFail {_ in
            let regErr = UIAlertController(title: "Register Error", message: "Could not register your device. Please check your internet connection and restart the app", preferredStyle: .alert)
            self.present(regErr, animated: true, completion: nil)
            return
        }
        
        // Checks if the Bluetooth permissions is OK + turned on
        bluetoothManager?.waiterDelegate = self
        switch bluetoothManager?.centralManager.state {
            case .unsupported, .unauthorized, .poweredOff, .none:
                let alert = UIAlertController(title: "Bluetooth Disabled", message: "Bluetooth is required", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
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
//        dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
        self.navigationController?.navigationBar.isHidden = false
    }
}

extension IntroViewController: AdvertismentWaiter {
    func bluetoothManager(_ manager: BluetoothManager, didStartAdvertising: Bool) {
        proceed()
    }
}
