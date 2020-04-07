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
        static let SERVICE_IDENTIFIER:CBUUID = {
            
            let identifier = UUID(uuidString: "0000FF01-0000-1000-8000-00805F9B34FB") // matches android app
            
            assert(identifier != nil, "Device Identifier must exist")
            return CBUUID(nsuuid: identifier ?? UUID())
        }()
        static let IDENTIFIER_KEY = "identifierForVendor"
        //        static let CHARACTERISTIC_VALUE = "Handshake Test"
        static let CHARACTERISTIC_VALUE = Constants.DEVICE_IDENTIFIER.uuidString
        static let HANDSHAKE_TIMEOUT: Double = 1.0
        static let HANDSHAKE_INTERVAL: Double = 3.0
        static let DEVICE_IDENTIFIER: UUID = {
            let identifier = UIDevice.current.identifierForVendor
            assert(identifier != nil, "Device Identifier must exist")
            return identifier ?? UUID()
        }()
        
        //TO DO: create setting for this
        static let USER_PROFILE = "\(UIDevice.current.name)"
    }
    
    lazy var centralManager: CBCentralManager = CBCentralManager(delegate: self, queue: nil)
    var peripheralManager: CBPeripheralManager!
    var currentPeripheral: CBPeripheral!
    
    var items = [node_data]()
    let viewController: ViewControllerInputs?
    weak var waiterDelegate: AdvertismentWaiter?
    
    lazy var locationService = LocationService()
    lazy var apiController = APIController()
    
    init(inputs: ViewControllerInputs?) {
        self.viewController = inputs
        super.init()
    }
    
    func restart() {
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        locationService.requestPermissions()
    }
    
    func detect() {
        items.removeAll()
        viewController?.reloadTable(indexPath: nil)
        guard centralManager.state == .poweredOn else {
            assertionFailure("Disable Detect Button if Central Manager is not powered on")
            return
        }
        
        //add interval after first peripheral detection
        if (items.count > 0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.HANDSHAKE_INTERVAL) {
                self.centralManager.scanForPeripherals(withServices: [ Constants.SERVICE_IDENTIFIER], options: nil)
            }
        }
            
        else {
            self.centralManager.scanForPeripherals(withServices: [ Constants.SERVICE_IDENTIFIER], options: nil)
        }
        
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            self.viewController?.waitForAdvertisment()
        }
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
        
        //REVIEW: Either Android can't advertise or iOS can't read this specific data
        let deviceIdentifier = ""
        //        guard !items.contains(where: {$0.peripheralIdentifier == peripheral.identifier}),
        //
        //            let deviceIdentifier = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        //
        //            else {
        //                print("ignoring: \(peripheral.identifier)")
        //            return
        //        }
        
        //append node
        let detected_node =  node_data(
            name: peripheral.name ?? "N/A",
            rssi: RSSI,
            timestamp: Date().timeIntervalSince1970,
            deviceIdentifier: deviceIdentifier,
            peripheralIdentifier: peripheral.identifier,
            coordinates: locationService.currentCoords,
            message: nil
        )
        
        //CBPeripheralManager advertises again when app enters background
        //Do not append if detected name and corresponding GPS is duplicate
        if !(items.contains {$0.name == peripheral.name} && items.contains {$0.coordinates.lat == locationService.currentCoords.lat} && items.contains {$0.coordinates.lon == locationService.currentCoords.lon}) {
            items.append(detected_node)
            //delegate for handshake procedure
            currentPeripheral = peripheral
            currentPeripheral.delegate = self
            
            //limit discovered peripherals to one device at a time
            central.stopScan()
            
            //connect to device
            central.connect(currentPeripheral, options: nil)
        }
        
        //reload table view
        DispatchQueue.main.async {
            self.viewController?.reloadTable(indexPath: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //        print("Successfully connected to \(peripheral.name ?? "N/A")")
        currentPeripheral.discoverServices(nil)
        
        //disconnect after timeout (enough time to handshake)
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.HANDSHAKE_TIMEOUT) {
            //            print("Disconnected after handshake timeout")
            central.cancelPeripheralConnection(self.currentPeripheral)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "N/A"), waiting \(Constants.HANDSHAKE_INTERVAL) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.HANDSHAKE_INTERVAL) {
            central.scanForPeripherals(withServices: [Constants.SERVICE_IDENTIFIER], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("\(peripheral.name ?? "N/A") disconnected, waiting \(Constants.HANDSHAKE_INTERVAL) seconds")
        
        //REVIEW: Implementation can be changed
        //check if node message is unset (handshake fail)
        if let itemIndex = items.firstIndex(where: {$0.peripheralIdentifier == peripheral.identifier && $0.message == nil }) {
            //indicate handshake fail
            items[itemIndex] = items[itemIndex].newWithMessage("Handshake fail")
        }
        
        //reload table view
        DispatchQueue.main.async {
            self.viewController?.reloadTable(indexPath: nil)
        }
        
        //scan for devices again
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.HANDSHAKE_INTERVAL) {
            central.scanForPeripherals(withServices: [ Constants.SERVICE_IDENTIFIER], options: nil)
        }
    }
    
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    func advertise(manager: CBPeripheralManager) {
        guard manager.state == .poweredOn else {
            print("CBPeripheralManager must be powered on")
            return
        }
        guard !manager.isAdvertising else {
            print("Advertising has already begun")
            return
        }
        
        // reset manager
        manager.stopAdvertising()
        manager.removeAllServices()
        
        //add service
        let service:CBMutableService = {
            
            //REVIEW: Set characteristic value as currentCoords or just use central's currentCoords upon handshake to send less bytes
            let sendMSG = Constants.CHARACTERISTIC_VALUE.data(using: .utf8)
            
            //create characteristics
            let characteristic = CBMutableCharacteristic(type: Constants.SERVICE_IDENTIFIER, properties: [.read], value: sendMSG, permissions: [.readable])
            //create service
            let service = CBMutableService(type: Constants.SERVICE_IDENTIFIER, primary: true)
            //set characteristic
            service.characteristics = [characteristic]
            return service
        }()
        manager.add(service)
        //start advertising
        
        // REVIEW: Advertises username for profiling
        // TO DO: Include a setting/text field to set this user profile
        manager.startAdvertising([
            CBAdvertisementDataLocalNameKey : Constants.USER_PROFILE,
            CBAdvertisementDataServiceUUIDsKey : [Constants.SERVICE_IDENTIFIER]
        ])
        waiterDelegate?.bluetoothManager(self, didStartAdvertising: true)
        print("Started Advertising")
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state != .poweredOn {
            viewController?.waitForAdvertisment()
        }
        switch peripheral.state {
        case .poweredOn:
            print("CBPeripheralManager powered on")
            advertise(manager: peripheral)
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
        viewController?.setPeripheral(status: peripheral.isAdvertising ? "ADVERTISING" : "NOT ADVERTISING")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Peripheral Manager Start Advertising Error: \(error.localizedDescription)")
        }
        
        viewController?.setPeripheral(status: peripheral.isAdvertising ? "ADVERTISING" : "NOT ADVERTISING")
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("\(peripheral.name ?? "N/A") services changed")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let lastService = peripheral.services?.last else { return }
        
        //        print("discovered services: \(lastService)")
        
        //REVIEW: Only detects the last service since handshake value is appended to list of services
        peripheral.discoverCharacteristics(nil, for: lastService)
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //checks all characteristics
        for characteristic: CBCharacteristic in service.characteristics! {
            //            print("Sending handshake to \(characteristic.uuid.uuidString)")
            
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
        let item = items[itemIndex].newWithMessage(recvMSG)
        items[itemIndex] = item
        apiController.send(item: item) { result in
            switch result {
            case .success(let pairedIDs):
                print("Sent: \(pairedIDs) to server")
            case .failure(let error):
                break
            }
        }
        //reload table view
        DispatchQueue.main.async {
            self.viewController?.reloadTable(indexPath: IndexPath(row: itemIndex, section: 0))
        }
        
        //disconnect
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
}
