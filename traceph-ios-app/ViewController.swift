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
    }
    
    struct node_data {
        var name: String
        var rssi: NSNumber
        var timestamp: String
        
        init(name: String, rssi: NSNumber, timestamp: String) {
            self.name = name
            self.rssi = rssi
            self.timestamp = timestamp
        }
    }
    
    var items = [node_data]()
    
    lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    lazy var peripheralManager: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    
    @IBOutlet weak var detectButton: UIButton!
    @IBOutlet weak var deviceTable: UITableView!
    
    @IBAction func detectPress(_ sender: Any) {
        items.removeAll()
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralStatus.text = "NOT ADVERTISING"
        
    }
    @IBOutlet weak var peripheralStatus: UILabel!
    private var identifier: CBUUID!

}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .poweredOn:
            print("powered on")
            self.detectButton.setTitle("DETECT",for: .normal)
            self.detectButton.isEnabled = true

        case .poweredOff:
            print("powered off state")
            self.detectButton.setTitle("BLUETOOTH OFF",for: .normal)
            self.detectButton.isEnabled = false
            
        case .unauthorized:
            print("unauthorized state")
        
        case .resetting:
            print("resetting state")
            
        case .unsupported:
            print("unsupported state")
            
        case .unknown:
            print("unknown state")
            
        default:
            print("error")

        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard !items.contains(where: {$0.rssi == RSSI}) else {
            return
        }
        //get timestamp
        let dateString: String = {
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.string(from: now)
        }()
        //append node
        let detected_node = node_data(name: peripheral.name ?? "N/A", rssi: RSSI, timestamp: dateString)
        items.append(detected_node)
        
        //reload table view
        DispatchQueue.main.async {
            self.deviceTable.reloadData()
        }
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
            
        case .poweredOn:
            print("powered on")
            
            //create new identifier
            identifier = CBUUID(nsuuid: UUID())
            
            //create characteristics
            let characteristic = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
                        
            //create service
            let service = CBMutableService(type: identifier, primary: true)
            
            //set characteristic
            service.characteristics = [characteristic]
            
            //add service
            peripheralManager.add(service)
            
            //start advertising
            peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : UIDevice.current.name, CBAdvertisementDataServiceUUIDsKey : [identifier]]  )
            
            print("Started Advertising")
            peripheralStatus.text = "ADVERTISING"
            
            

        case .poweredOff:
            print("powered off state")
            
        case .unauthorized:
            print("unauthorized state")
        
        case .resetting:
            print("resetting state")
            
        case .unsupported:
            print("unsupported state")
            
        case .unknown:
            print("unknown state")
            
        default:
            assertionFailure("handle \(peripheral.state) state")
        }
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
        cell.detailTextLabel?.text = "\(node.rssi)\t-\t\(node.timestamp)"
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
}
