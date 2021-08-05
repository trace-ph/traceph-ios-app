//
//  AboutUsViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 7/27/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit

class AboutUsViewController: UIViewController {
    struct Constants {
        static let email = "detectph.updsc@gmail.com"
        static let privacy = "https://www.detectph.com/privacy.html"
    }
    
    @IBOutlet weak var AboutTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AboutTextView?.text += "(\(Constants.privacy)), please email us through \(Constants.email) with the subject \"DetectPH Concern\""
        AboutTextView?.sizeToFit()
        AboutTextView?.isScrollEnabled = false
    }
}
