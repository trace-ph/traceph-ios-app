//
//  NotificationViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 7/27/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var notifTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "CardTableViewCell", bundle: nil)
        notifTableView.register(nib, forCellReuseIdentifier: "CardTableViewCell")
        notifTableView.delegate = self
        notifTableView.dataSource = self
        notifTableView.tableFooterView = UIView()
    }
    
    // Notification Table functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = notifTableView.dequeueReusableCell(withIdentifier: "CardTableViewCell", for: indexPath) as! CardTableViewCell
        
        // Get the saved notification
        let notifLabel = DefaultsKeys.notifLabel.dictArrayValue as? [String]
        let notifDesc = DefaultsKeys.notifDesc.dictArrayValue as? [String]
        cell.cardLabel?.text = notifLabel?[indexPath.row + 1] ?? "Date received"
        cell.cardDesc?.text = notifDesc?[indexPath.row + 1] ?? "Notification details"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
    }
    
}
