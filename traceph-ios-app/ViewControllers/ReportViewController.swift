//
//  ReportViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 7/27/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit

class ReportViewController: UIViewController {
    
    @IBOutlet weak var startReportView: UIView?
    @IBOutlet weak var reportHeaderView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = startReportView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismiss(animated: true, completion: nil)
    }
}
