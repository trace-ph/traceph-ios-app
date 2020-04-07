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
    func reloadTable(indexPath: IndexPath?)
    func setPeripheral(status: String?)
    func waitForAdvertisment()
}


class ViewController: UIViewController {
    struct Constants {
        static let REUSE_IDENTIFIER = "discoveredNodeCell"
        static let downloadURL: String = "https://endcov.ph/dashboard/"
    }
    
    enum Segues: String {
        case intro = "intro"
        case authorize = "authorize"
        
        func perform(controller: UIViewController, sender: Any?) {
            controller.performSegue(withIdentifier: self.rawValue, sender: sender)
        }
    }
        
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    var bluetoothManager: BluetoothManager!

    @IBOutlet weak var debugView: UIView?
    @IBOutlet weak var shareView: UIView?
    @IBOutlet weak var shareTextView: UITextView?
    @IBOutlet weak var detectButton: UIButton?
    @IBOutlet weak var deviceTable: UITableView?
    @IBOutlet weak var qrTextView: UITextView!

    @IBAction func detectPress(_ sender: UIButton?) {
        bluetoothManager.detect()
    }
    
    @IBAction func copyAction(_ sender: UIButton?) {
        UIPasteboard.general.string = Constants.downloadURL
    }
    
    func updateTextFont(textView: UITextView) {
        if (textView.text.isEmpty || textView.bounds.size.equalTo(CGSize.zero)) {
            return;
        }

        let textViewSize = textView.frame.size;
        let fixedWidth = textViewSize.width;
        let expectSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)))

        var expectFont = textView.font;
        if (expectSize.height > textViewSize.height) {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height) {
                expectFont = textView.font!.withSize(textView.font!.pointSize - 1)
                textView.font = expectFont
            }
        }
        else {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height) {
                expectFont = textView.font;
                textView.font = textView.font!.withSize(textView.font!.pointSize + 1)
            }
            textView.font = expectFont;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bluetoothManager = BluetoothManager(inputs: self)
        #if DEBUG
        shareView = nil
        view = debugView
        #else
        debugView = nil
        view = shareView
        bluetoothManager.detect()
        shareTextView?.text += "\n\(Constants.downloadURL)"
//        shareTextView?.translatesAutoresizingMaskIntoConstraints = true
        shareTextView?.sizeToFit()
        shareTextView?.isScrollEnabled = false
//        qrTextView?.translatesAutoresizingMaskIntoConstraints = true
        qrTextView?.sizeToFit()
        qrTextView?.isScrollEnabled = false
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkForModals()
    }
    
    func checkForModals() {
        if !DefaultsKeys.userHasConsented.boolValue {
            Segues.intro.perform(controller: self, sender: nil)
        } else if bluetoothManager.centralManager.state != .poweredOn {
            waitForAdvertisment()
        } else {
            bluetoothManager.detect()
        }
    }
    
    func waitForAdvertisment() {
        guard presentedViewController == nil else {
            return
        }
        print("presenting waiter")
        Segues.authorize.perform(controller: self, sender: nil)
    }
    
    @IBOutlet weak var peripheralStatus: UILabel!
    @IBOutlet weak var deviceProfile: UILabel!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? AdvertismentWaiter else {
            return
        }
        controller.bluetoothManager = self.bluetoothManager
    }
}

extension ViewController: ViewControllerInputs {
    func reloadTable(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            deviceTable?.reloadRows(at: [indexPath], with: .automatic)
        } else {
            deviceTable?.reloadData()
        }
    }
    
    var controller: ViewController {
        return self
    }
    func setDetectButton(enabled: Bool) {
        detectButton?.isEnabled = enabled
        detectButton?.alpha = enabled ? 1 : 0.5
        if !enabled {
            waitForAdvertisment()
        }
    }
    
    func reloadTable() {
        deviceTable?.reloadData()
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
        let coordinates = bluetoothManager.locationService.currentCoords
        let currentLat = String(format: "%.6f", coordinates.lat)
        let currentLon = String(format: "%.6f", coordinates.lon)

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

extension UITextView {
    func decreaseFontSize () {
        self.font =  UIFont(name: self.font!.fontName, size: self.font!.pointSize-1)!
    }
}