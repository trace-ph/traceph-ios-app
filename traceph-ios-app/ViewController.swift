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

// REVIEW: Maybe convert this into a struct
// timestamp may be useful to differentiate with bluetooth timestamp to indicate accuracy of location
typealias SimpleCoordinates = (lon: Double, lat: Double, timestamp: Double)

class ViewController: UIViewController {
    struct Constants {
        static let REUSE_IDENTIFIER = "discoveredNodeCell"
        static let IDENTIFIER_KEY = "identifierForVendor"
        static let CHARACTERISTIC_VALUE = "Handshake"
    }
    
    struct node_data {
        var name: String
        let rssi: NSNumber
        let timestamp: Double
        let deviceIdentifier: String
        let coordinates: SimpleCoordinates
        func dateString(formatter: DateFormatter) -> String {
            let date = Date(timeIntervalSince1970: timestamp)
            return formatter.string(from: date)
        }
    }
    
    var items = [node_data]()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    var currentCoords: SimpleCoordinates = (lon: Double.nan, lat: Double.nan, timestamp: Double.nan)
    
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    
    var currentPeripheral: CBPeripheral!
    
    lazy var locationManager:CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 10
        manager.pausesLocationUpdatesAutomatically = true
        return manager
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
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
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
            !items.contains(where: {$0.deviceIdentifier == deviceIdentifier}) else {
//                print("ignoring \(peripheral.name ?? "unknown") with rssi: \(RSSI)")
            return
        }
        
        //append node
        let detected_node =  node_data(
            name: peripheral.name ?? "unknown",
            rssi: RSSI,
            timestamp: Date().timeIntervalSince1970,
            deviceIdentifier: deviceIdentifier,
            coordinates: currentCoords
            )
        items.append(detected_node)
        
        //delegate for handshake procedure
        currentPeripheral = peripheral
        currentPeripheral.delegate = self
        
        //limit discovered peripherals to one device at a time
        centralManager.stopScan()
        
        //connect to device
        centralManager?.connect(currentPeripheral, options: nil)
        
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
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("\(peripheral.name ?? "N/A") disconnected")
        
        //REVIEW: Implementation can be changed
        //check if node name is unchanged (handshake fail)
        if (items.contains{$0.name == peripheral.name}) {
            
            //find device index in tableview
            let indexPath = items.firstIndex { (item) -> Bool in
              item.name == peripheral.name
            }
            
            //indicate handshake fail
            items[indexPath!].name = "\(items[indexPath!].name)\t-\tHandshake fail"
        }
        
        //reload table view
        DispatchQueue.main.async {
            self.deviceTable.reloadData()
        }
        
        //scan for devices again
        centralManager.scanForPeripherals(withServices: nil, options: nil)
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
            let characteristic = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.read], value: sendMSG.data(using: .utf8), permissions: [.readable])
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
        guard let services = peripheral.services else { return }

        //REVIEW: Only detects the last service since handshake value is appended to list of services
        peripheral.discoverCharacteristics(nil, for: services[services.endIndex - 1])
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        //checks all characteristics
        for characteristic: CBCharacteristic in service.characteristics! {
            print("Sending handshake to \(characteristic.uuid.uuidString)")
            
            peripheral.readValue(for: characteristic)
            
            //disconnect after N seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        // indicates successful handshakes in device table for now
        // REVIEW: Name is not a good identifier because it's not unique.
        // Since we only plan on connecting to one, why use item array at all?
        guard let itemIndex = items.firstIndex(where: {$0.name == peripheral.name }) else {
            assertionFailure("items does not contain: \(peripheral.name)")
            return
        }
        
        //TODO: Process received data from peripheral to server
        var recvMSG = String(decoding:data, as: UTF8.self)
        
        if recvMSG == Constants.CHARACTERISTIC_VALUE {
            recvMSG = recvMSG + " success"
            items[itemIndex].name = "\(items[itemIndex].name)\t-\t\(recvMSG)"
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
        cell.textLabel?.text = node.name
        
        //REVIEW: Create UITableViewCell depending on needed information
        cell.detailTextLabel?.text = "\(node.rssi)\t-\t\(node.dateString(formatter: dateFormatter))"
        
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            
        case .denied:
            print("location auth denied")
        
        case .notDetermined:
            print("location auth not determined")
            
        case .restricted:
            print("location auth restricted")
            
        default:
            print("location auth error")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinates: CLLocationCoordinate2D = locations.last?.coordinate else { return }
        
//        print("coordinates= \(coordinates.latitude) \(coordinates.longitude)")
        
        currentCoords.lat = coordinates.latitude
        currentCoords.lon = coordinates.longitude
        currentCoords.timestamp = Date().timeIntervalSince1970
        
    }
    
}
