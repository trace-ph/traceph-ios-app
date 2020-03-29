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

class ViewController: UIViewController {
    struct Constants {
        static let REUSE_IDENTIFIER = "discoveredNodeCell"
        static let IDENTIFIER_KEY = "identifierForVendor"
    }
    
    struct node_data {
        let name: String
        let rssi: NSNumber
        let timestamp: Double
        let deviceIdentifier: String
        
        func dateString(formatter: DateFormatter) -> String {
            let date = Date(timeIntervalSince1970: timestamp)
            return formatter.string(from: date)
        }
    }
    
    var items = [node_data]()
    
    lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    lazy var peripheralManager: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    @IBOutlet weak var detectButton: UIButton!
    @IBOutlet weak var deviceTable: UITableView!
    
    @IBAction func detectPress(_ sender: UIButton?) {
        items.removeAll()
        deviceTable.reloadData()
        guard centralManager.state == .poweredOn else {
            sender?.isEnabled = false
            assertionFailure("Disable Detect Button if Central Manager is not powered on")
            return
        }
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detectButton.isEnabled = centralManager.state == .poweredOn
        advertise(manager: peripheralManager, identifier: CBUUID(nsuuid: UUID()))
    }
    
    @IBOutlet weak var peripheralStatus: UILabel!
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.detectButton.isEnabled = central.state == .poweredOn
        self.detectButton.alpha = self.detectButton.isEnabled ? 1 : 0.5
        switch central.state {
        case .poweredOn:
            print("CBCentralManager powered on")
        case .poweredOff:
            print("CBCentralManager powered off state")
        case .unauthorized:
            print("CBCentralManager unauthorized state")
        case .resetting:
            print("CBCentralManager resetting state")
        case .unsupported:
            print("CBCentralManager unsupported state")
        case .unknown:
            print("CBCentralManager unknown state")
        default:
            print("CBCentralManager error")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard
            let deviceIdentifier = advertisementData[Constants.IDENTIFIER_KEY] as? String,
            !items.contains(where: {$0.deviceIdentifier == deviceIdentifier}) else {
            return
        }
        //append node
        let detected_node =  node_data(
            name: peripheral.name ?? "unknown",
            rssi: RSSI,
            timestamp: Date().timeIntervalSince1970,
            deviceIdentifier: deviceIdentifier)
        items.append(detected_node)
        
        //reload table view
        DispatchQueue.main.async {
            self.deviceTable.reloadData()
        }
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    func advertise(manager: CBPeripheralManager, identifier: CBUUID) {
        guard manager.state == .poweredOn else {
            print("CBPeripheralManager must be powered on")
            return
        }
        guard !manager.isAdvertising else {
            print("Advertising has already begun")
            return
        }
        // REVIEW: does this really need to be done every time we want to advertise?
        // reset manager
        manager.stopAdvertising()
        manager.removeAllServices()
        
        //add service
        let service:CBMutableService = {
            //create characteristics
            let characteristic = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
            //create service
            let service = CBMutableService(type: identifier, primary: true)
            //set characteristic
            service.characteristics = [characteristic]
            return service
        }()
        manager.add(service)
        
        //start advertising
        let advertisementData:[String:Any] = [
            CBAdvertisementDataLocalNameKey : UIDevice.current.name,
            CBAdvertisementDataServiceUUIDsKey : [identifier],
            Constants.IDENTIFIER_KEY: Utility.getDeviceIdentifier()
        ]
        manager.startAdvertising(advertisementData)
        print("Started Advertising")
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("CBPeripheralManager powered on")
            advertise(manager: peripheral, identifier: CBUUID(nsuuid: UUID()))
        default:
            switch peripheral.state {
                case .poweredOff:
                    print("CBPeripheralManagerDelegate powered off state")
                case .unauthorized:
                    print("CBPeripheralManagerDelegate unauthorized state")
                case .resetting:
                    print("CBPeripheralManagerDelegate resetting state")
                case .unsupported:
                    print("CBPeripheralManagerDelegate unsupported state")
                case .unknown:
                    print("CBPeripheralManagerDelegate unknown state")
                default:
                    assertionFailure("handle \(peripheral.state.rawValue) state")
            }
        }
        peripheralStatus.text = peripheral.isAdvertising ? "ADVERTISING" : "NOT ADVERTISING"
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIER) else {
            assertionFailure("Register \(Constants.REUSE_IDENTIFIER) cell first")
            return UITableViewCell()
        }
        let node = items[indexPath.row]
        cell.textLabel?.text = node.name
        cell.detailTextLabel?.text = "\(node.rssi)\t-\t\(node.dateString(formatter: dateFormatter))"
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
}
