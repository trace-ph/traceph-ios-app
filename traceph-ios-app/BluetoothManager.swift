//
//  BluetoothManager.swift
//  traceph-ios-app
//
//  Created by Enzo on 30/03/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

import CoreBluetooth
import UIKit.UIDevice

class BluetoothManager: NSObject {
    struct Constants {
        static let IDENTIFIER_KEY = "identifierForVendor"
        static let CHARACTERISTIC_VALUE = "Handshake"
        static let HANDSHAKE_TIMEOUT: Double = 1.0
    }
    
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    var currentPeripheral: CBPeripheral!
    
    var items = [node_data]()
    let viewController: ViewControllerInputs
    
    lazy var locationService = LocationService()
    
    init(controller: ViewControllerInputs) {
        self.viewController = controller
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        locationService.requestPermissions()
    }
    
    func detect() {
        items.removeAll()
        viewController.reloadTable(indexPath: nil)
        guard centralManager.state == .poweredOn else {
            viewController.setDetectButton(enabled: false)
            assertionFailure("Disable Detect Button if Central Manager is not powered on")
            return
        }
        centralManager.scanForPeripherals(withServices: nil)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
        
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.viewController.setDetectButton(enabled: central.state == .poweredOn)
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
            self.viewController.reloadTable(indexPath: nil)
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
            self.viewController.reloadTable(indexPath: nil)
        }
        
        //scan for devices again
        central.scanForPeripherals(withServices: nil, options: nil)
    }
}

extension BluetoothManager: CBPeripheralManagerDelegate {
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
        viewController.setPeripheral(status: peripheral.isAdvertising ? "ADVERTISING" : "NOT ADVERTISING")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Peripheral Manager Start Advertising Error: \(error.localizedDescription)")
        }
        
        viewController.setPeripheral(status: peripheral.isAdvertising ? "ADVERTISING" : "NOT ADVERTISING")
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
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
            self.viewController.reloadTable(indexPath: IndexPath(row: itemIndex, section: 0))
        }
        
        //disconnect
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
