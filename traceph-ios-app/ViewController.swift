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
        static let REUSE_IDENTIFIER = "CollectionViewCell"
    }
    
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
    
    var currentCoords: (Double,Double) = (0,0)
    
    lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    var peripheralManager: CBPeripheralManager!
    var locationManager = CLLocationManager()

    @IBOutlet weak var deviceCV: UICollectionView!
    @IBOutlet weak var detectButton: UIButton!
    
    @IBAction func detectPress(_ sender: Any) {
        items.removeAll()
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralStatus.text = "NOT ADVERTISING"
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        getLocation(locationManager: locationManager)
    }

    
    @IBOutlet weak var peripheralStatus: UILabel!
    private var identifier: CBUUID!

}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .poweredOn:
//            print("powered on")
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
            let detected_node = node_data(name: peripheral.name ?? "N/A", rssi: Int(RSSI), timestamp: dateString)
            
            items.append(detected_node)
            
//            print(detected_node)
            
            //reload collection view
            DispatchQueue.main.async {
                self.deviceCV.reloadData()
            }
        }
}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
            
        case .poweredOn:
//            print("powered on")
            
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

extension ViewController: UICollectionViewDelegate {
    
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewController.Constants.REUSE_IDENTIFIER, for: indexPath) as? CollectionViewCell else {
            assertionFailure("Register \(ViewController.Constants.REUSE_IDENTIFIER) cell first")
            return UICollectionViewCell()
        }
        let item = items[indexPath.row]
        cell.nodeName.text = item.name
        cell.nodeRSSI.text = String(item.rssi)
        cell.nodeTimestamp.text = item.timestamp
        return cell
    }
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
