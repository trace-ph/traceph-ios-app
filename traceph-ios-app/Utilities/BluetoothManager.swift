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
        static let HANDSHAKE_TIMEOUT: Double = 1.0
        static let HANDSHAKE_INTERVAL: Double = 3.0
        
        //TO DO: create setting for this
        static let USER_PROFILE = "\(UIDevice.current.name)"
    }
    
    lazy var centralManager: CBCentralManager = CBCentralManager(delegate: self, queue: nil)
    var peripheralManager: CBPeripheralManager!
    var currentPeripheral: CBPeripheral!
    
    var discoveryLog = [node_data]()
    var localStorage = [node_data]()
    var toConnect = [CBPeripheral]()
    var recognizedDevice = [device_data]()
    let viewController: ViewControllerInputs?
    weak var waiterDelegate: AdvertismentWaiter?
    
    var stopBluetooth = true;       // Will state whether to stop Bluetooth operations (contact-tracing)
    
    lazy var locationService = LocationService()
    init(inputs: ViewControllerInputs?) {
        self.viewController = inputs
        super.init()
    }
    
    func restart() {
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        locationService.requestPermissions()
    }
    
    func detect() {
        stopBluetooth = false
        viewController?.reloadTable(indexPath: nil)
        guard centralManager.state == .poweredOn else {
            assertionFailure("Disable Detect Button if Central Manager is not powered on")
            return
        }
        
        startTimer()
    }
    
    // Stops scanning
    func stop() {
        NSLog("Stopping scan and advertising...")
        stopBluetooth = true
        self.centralManager.stopScan()
        self.peripheralManager.stopAdvertising()
        
        if(!self.centralManager.isScanning && !self.peripheralManager.isAdvertising){
            print("Scanning and advertising is successfully stopped")
        }
    }
    
    func startTimer(){
        discoveryLog.removeAll()
        if(stopBluetooth){
            return
        }
        
        // Start advertising if previously closed
        if(!peripheralManager.isAdvertising){
            peripheralManager.startAdvertising([
                CBAdvertisementDataLocalNameKey : Constants.USER_PROFILE,
                CBAdvertisementDataServiceUUIDsKey : [Constants.SERVICE_IDENTIFIER]
            ])
        }
        
        NSLog("Calling scan for peripherals (startTimer)...")
        self.centralManager.scanForPeripherals(withServices: [ Constants.SERVICE_IDENTIFIER], options: nil)
        self.perform(#selector(endScanning), with: self, afterDelay: 1);  // Stops scanning after 1 second
        
        
    }
    
    // What happens after
    @objc func endScanning(_ central: CBCentralManager) {
        self.centralManager.stopScan()
        NSLog("Scanning ended")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.HANDSHAKE_INTERVAL) { [self] in
            startTimer()
        }
        
        if(discoveryLog.isEmpty){
            return
        }
        
        for node in discoveryLog {
            // Check if it's already recognized; No need to connect if so
            // If the same device is detected within a certain time interval, don't append
            if let recogDevIndex = recognizedDevice.firstIndex(where: {$0.peripheralIdentifier == node.peripheralIdentifier }){
                if !(localStorage.contains {$0.message == recognizedDevice[recogDevIndex].node_id && $0.timestamp + 2 >= node.timestamp}){
//                    print("NodeID: ", recognizedDevice[recogDevIndex].node_id)
                    let newNode = node.newWithMessage(recognizedDevice[recogDevIndex].node_id);
                    localStorage.append(newNode)
                }
            }

            // Connect to all unrecognized devices
            else {
                let peripheralIndex = toConnect.firstIndex(where: {$0.identifier == node.peripheralIdentifier})
                currentPeripheral = toConnect[peripheralIndex!]
                currentPeripheral.delegate = self
                
                print("Connecting to: ", currentPeripheral!)
                centralManager.connect(currentPeripheral, options: nil)
                usleep(500)     // Delay before continuing on
            }
        }
        
        // Send info to server
        print("Recognized devices: ", recognizedDevice)
        print("Discovery Log: ", discoveryLog)
        print("Local Storage: ", localStorage)
        APIController.sourceNodeID.onSucceed { [self] value in
            APIController().send(items: localStorage, sourceNodeID: value) { [self] result in
                switch result {
                case .success(let pairedIDs):
                    print("Sent: \(pairedIDs) to server")
                    toConnect.removeAll()
                    localStorage.removeAll()
                case .failure(let error):
                    print(error)
                    toConnect.removeAll()
                    localStorage.removeAll()
                }
            }
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
        
        if (stopBluetooth){
            stop()
            return
        }
        
        //REVIEW: Either Android can't advertise or iOS can't read this specific data
        let deviceIdentifier = ""
        //        guard !discoveryLog.contains(where: {$0.peripheralIdentifier == peripheral.identifier}),
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
            txPower: advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber,
            timestamp: Date().timeIntervalSince1970,
            deviceIdentifier: deviceIdentifier,
            peripheralIdentifier: peripheral.identifier,
//            coordinates: locationService.currentCoords,
            message: nil
        )
        
        // To avoid detecting the same ID within scanning intervals
        if !(discoveryLog.contains {$0.peripheralIdentifier == peripheral.identifier}){
            discoveryLog.append(detected_node)
            
            //delegate for handshake procedure
            currentPeripheral = peripheral
            currentPeripheral.delegate = self
            toConnect.append(currentPeripheral!)
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
        print("Failed to connect to \(peripheral.name ?? "N/A")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("\(peripheral.name ?? "N/A") disconnected")
        
        //REVIEW: Implementation can be changed
        //check if node message is unset (handshake fail)
        if let itemIndex = discoveryLog.firstIndex(where: {$0.peripheralIdentifier == peripheral.identifier && $0.message == nil }) {
            // Check if it's already recognized
            if let recogDevIndex = recognizedDevice.firstIndex(where: {$0.peripheralIdentifier == peripheral.identifier }){
                discoveryLog[itemIndex] = discoveryLog[itemIndex].newWithMessage(recognizedDevice[recogDevIndex].node_id);
            } else {
                //indicate handshake fail
                discoveryLog[itemIndex] = discoveryLog[itemIndex].newWithMessage("Handshake fail")
            }
        }
        
        //reload table view
        DispatchQueue.main.async {
            self.viewController?.reloadTable(indexPath: nil)
        }
    }
    
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    func advertise(manager: CBPeripheralManager, characteristicValue: String) {
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
            let sendMSG = characteristicValue.data(using: .utf8)
            
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
            APIController.sourceNodeID.observe(using: { [weak self] result in
                switch result {
                case .success(let value):
                    self?.advertise(manager: peripheral, characteristicValue: value)
                case .failure(let error):
                    print(error)
                }
            })
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
        
        // Process received data from peripheral to server and save it to be sent to server
        guard let discIndex = discoveryLog.firstIndex(where: { $0.peripheralIdentifier == peripheral.identifier }) else {
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        let recvMSG = String(decoding:data, as: UTF8.self)
        print(discIndex)
        let item = discoveryLog[discIndex].newWithMessage(recvMSG)
        discoveryLog[discIndex] = item
        localStorage.append(item)
        print(localStorage)
        
        // Add unrecognized devices
        if(!recognizedDevice.contains {$0.peripheralIdentifier == peripheral.identifier}){
            recognizedDevice.append(device_data(
                peripheralIdentifier: peripheral.identifier, node_id: recvMSG
            ))
        }
        
        //disconnect
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
}
