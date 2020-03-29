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

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,  CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    
    
    struct node_data {
        var name: String
        var rssi: Int
        var timestamp: String
        
        init(name: String, rssi: Int, timestamp: String) {
            self.name = name
            self.rssi = rssi
            self.timestamp = timestamp
        }
    }
    
    var items = [node_data]()
    
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    
    @IBOutlet weak var deviceCV: UICollectionView!
    @IBOutlet weak var detectButton: UIButton!
    
    @IBAction func detectPress(_ sender: Any) {
        items.removeAll()
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        peripheralStatus.text = "NOT ADVERTISING"
        
    }
    
    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        cell.nodeName.text = items[indexPath.row].name
        cell.nodeRSSI.text = String(items[indexPath.row].rssi)
        cell.nodeTimestamp.text = items[indexPath.row].timestamp
    
        return cell
    }
    
    
    // MARK: - CoreBluetooth Central
    
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
        
        //get timestamp
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: now)
        
        //append node
//        let detected_node = node_data(name: peripheral.name ?? peripheral.identifier.uuidString, rssi: Int(RSSI), timestamp: dateString)
        
        let detected_node = node_data(name: peripheral.name ?? "N/A", rssi: Int(RSSI), timestamp: dateString)
        
        items.append(detected_node)
        
//        print(detected_node)
        
        //reload collection view
        DispatchQueue.main.async {
            self.deviceCV.reloadData()
        }
    }
    
    // MARK: - CoreBluetooth Peripheral
    
    @IBOutlet weak var peripheralStatus: UILabel!
    
    private var identifier: CBUUID!
    
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
            print("error")

        }
    }

}

