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
import CoreLocation

class ViewController: UIViewController {
    struct Constants {
        static let REUSE_IDENTIFIER = "discoveredNodeCell"
        static let IDENTIFIER_KEY = "identifierForVendor"
        static let CHARACTERISTIC_VALUE = "Handshake"
        static let HANDSHAKE_TIMEOUT: Double = 1.0
    }
    
    struct node_data {
        let name: String
        let rssi: NSNumber
        let timestamp: Double
        let deviceIdentifier: String
        let peripheralIdentifier: UUID
        let coordinates: SimpleCoordinates
        let message: String? // maybe convert to a bool `didConnect`
        
        func dateString(formatter: DateFormatter) -> String {
            let date = Date(timeIntervalSince1970: timestamp)
            return formatter.string(from: date)
        }
        
        func newWithMessage(_ message: String?) -> node_data {
            return node_data(
                name: name,
                rssi: rssi,
                timestamp: timestamp,
                deviceIdentifier: deviceIdentifier,
                peripheralIdentifier: peripheralIdentifier,
                coordinates: coordinates,
                message: message)
        }
    }
    
    var items = [node_data]()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    
    var currentPeripheral: CBPeripheral!
    
    lazy var locationService = LocationService()

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
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        locationService.requestPermissions()
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
            let deviceIdentifier = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.last?.uuidString,
            !items.contains(where: {$0.peripheralIdentifier == peripheral.identifier}) else {
            return
        }
        
        //append node
        let detected_node =  node_data(
            name: peripheral.name ?? "unknown",
            rssi: RSSI,
            timestamp: Date().timeIntervalSince1970,
            deviceIdentifier: deviceIdentifier,
            peripheralIdentifier: peripheral.identifier,
            coordinates: locationService.currentCoords,
            message: nil
            )
        items.append(detected_node)
        
        //delegate for handshake procedure
        currentPeripheral = peripheral
        currentPeripheral.delegate = self
        
        //limit discovered peripherals to one device at a time
        central.stopScan()
        
        //connect to device
        central.connect(currentPeripheral, options: nil)
        
        //reload table view
        DispatchQueue.main.async {
            self.deviceTable.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Successfully connected to \(peripheral.name ?? "N/A")")
        currentPeripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "N/A")")
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("\(peripheral.name ?? "N/A") disconnected")
        
        //REVIEW: Implementation can be changed
        //check if node message is unset (handshake fail)
        if let itemIndex = items.firstIndex(where: {$0.peripheralIdentifier == peripheral.identifier && $0.message == nil }) {
             //indicate handshake fail
            items[itemIndex] = items[itemIndex].newWithMessage("Handshake fail")
        }
        
        //reload table view
        DispatchQueue.main.async {
            self.deviceTable.reloadData()
        }
        
        //scan for devices again
        central.scanForPeripherals(withServices: nil, options: nil)
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
        manager.removeAllServices() //ASTI: I think this needs to be done because my code assumes that the last appended service is the one that contains the handshake message
        
        //add service
        let service:CBMutableService = {
            
            //REVIEW: Set characteristic value as currentCoords or just use central's currentCoords upon handshake to send less bytes
            let sendMSG = Constants.CHARACTERISTIC_VALUE.data(using: .utf8)
            
            //create characteristics
            let characteristic = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.read], value: sendMSG, permissions: [.readable])
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
            CBAdvertisementDataServiceUUIDsKey : [identifier]
        ]
        manager.startAdvertising(advertisementData)
        print("Started Advertising")
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("CBPeripheralManager powered on")
            // TODO: replace identifier with whatever we plan on using. Maybe fingerprintjs
            // REVIEW: Is this how to properly pass the fingerprint? As an element in CBAdvertisementDataServiceUUIDsKey
            guard let identifier = UIDevice.current.identifierForVendor else {
                return
            }
            advertise(manager: peripheral, identifier: CBUUID(nsuuid: identifier))
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
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print(error?.localizedDescription)
        peripheralStatus.text = peripheral.isAdvertising ? "ADVERTISING" : "NOT ADVERTISING"
    }
}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("\(peripheral.name ?? "N/A") services changed")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let lastService = peripheral.services?.last else { return }
        //REVIEW: Only detects the last service since handshake value is appended to list of services
        peripheral.discoverCharacteristics(nil, for: lastService)
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        //checks all characteristics
        for characteristic: CBCharacteristic in service.characteristics! {
            print("Sending handshake to \(characteristic.uuid.uuidString)")
            
            peripheral.readValue(for: characteristic)
            
            //disconnect after N seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.HANDSHAKE_TIMEOUT) {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        // indicates successful handshakes in device table for now
        // REVIEW: Changed identifier to peripheral.identifier instead of name because name is not unique
        // Since we only plan on connecting to one, why use item array at all?
        guard let itemIndex = items.firstIndex(where: {$0.peripheralIdentifier == peripheral.identifier }) else {
            assertionFailure("items does not contain: \(peripheral.identifier)")
            return
        }
        
        //TODO: Process received data from peripheral to server
        let recvMSG = String(decoding:data, as: UTF8.self)
        
        if recvMSG == Constants.CHARACTERISTIC_VALUE {
            items[itemIndex] = items[itemIndex].newWithMessage(recvMSG + " success")
        }
        
        //reload table view
        DispatchQueue.main.async {
            self.deviceTable.reloadData()
        }
        
        //disconnect
        centralManager.cancelPeripheralConnection(peripheral)
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
        if let message = node.message {
            cell.textLabel?.text = "\(node.name)\t-\t\(message)"
        } else {
            cell.textLabel?.text = node.name
        }
        
        //REVIEW: Create UITableViewCell depending on needed information
        cell.detailTextLabel?.text = "\(node.rssi)\t-\t\(node.dateString(formatter: dateFormatter))"
        
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
