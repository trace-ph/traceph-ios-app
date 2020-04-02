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

protocol ViewControllerInputs {
    //NOTE: creating these functions may slow you down so you can just do `viewController.controller.deviceTable` or something for quicker access.
    var controller: ViewController { get }
    func setDetectButton(enabled: Bool)
    func reloadTable(indexPath: IndexPath?)
    func setPeripheral(status: String?)
}

class ViewController: UIViewController {
    struct Constants {
        static let REUSE_IDENTIFIER = "discoveredNodeCell"
    }
        
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    var bluetoothManager: BluetoothManager!

    @IBOutlet weak var detectButton: UIButton!
    @IBOutlet weak var deviceTable: UITableView!
    
    @IBAction func detectPress(_ sender: UIButton?) {
        bluetoothManager.detect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bluetoothManager = BluetoothManager(controller: self)
    }
    
    @IBOutlet weak var peripheralStatus: UILabel!
    @IBOutlet weak var deviceProfile: UILabel!
}

extension ViewController: ViewControllerInputs {
    func reloadTable(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            deviceTable.reloadRows(at: [indexPath], with: .automatic)
        } else {
            deviceTable.reloadData()
        }
    }
    
    var controller: ViewController {
        return self
    }
    func setDetectButton(enabled: Bool) {
        detectButton.isEnabled = enabled
        detectButton.alpha = enabled ? 1 : 0.5
    }
    
    func reloadTable() {
        deviceTable.reloadData()
    }
    
    func setPeripheral(status: String?) {
        peripheralStatus.text = status
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothManager.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIER) else {
            assertionFailure("Register \(Constants.REUSE_IDENTIFIER) cell first")
            return UITableViewCell()
        }

        let node = bluetoothManager.items[indexPath.row]
        if let message = node.message {
            cell.textLabel?.text = "\(node.name)\t-\t\(message)"
        } else {
            cell.textLabel?.text = node.name
        }
        
        let currentLat = String(format: "%.6f", bluetoothManager.locationService.currentCoords.lat)
        let currentLon = String(format: "%.6f", bluetoothManager.locationService.currentCoords.lon)

        //REVIEW: Create UITableViewCell depending on needed information
        cell.detailTextLabel?.text = "\(node.rssi)\t-\t\(node.dateString(formatter: dateFormatter))\t-\t[\(currentLat), \(currentLon)]"
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
