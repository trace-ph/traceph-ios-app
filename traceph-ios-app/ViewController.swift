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
import MapKit

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
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    var currentCoords: (Double,Double) = (0,0)
    
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    lazy var locationManager = CLLocationManager()

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
                print("ignoring \(peripheral.name) with rssi: \(RSSI)")
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

extension ViewController: CLLocationManagerDelegate {
    
    func getLocation(locationManager: CLLocationManager) {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 10
        locationManager.pausesLocationUpdatesAutomatically = true
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
//        locationManager.allowsBackgroundLocationUpdates = true
    }
    
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
        guard let coordinates: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
       print("coordinates= \(coordinates.latitude) \(coordinates.longitude)")
        
        currentCoords.0 = coordinates.latitude
        currentCoords.1 = coordinates.longitude
        
    }
    
}
