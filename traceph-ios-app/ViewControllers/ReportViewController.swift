//
//  ReportViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 7/27/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit
import DatePicker

class ReportViewController: UIViewController {
    
    @IBOutlet weak var startReportView: UIView?
    @IBOutlet weak var reportHeaderView: UIImageView!
    
    @IBOutlet weak var inputResultsView: UIView?
    @IBOutlet weak var testDateBtn: UIButton?
    @IBOutlet weak var recvDateBtn: UIButton?
    @IBOutlet weak var covidResult: UISwitch?
    @IBOutlet weak var covidResultText: UILabel?
    var testDate: Date!
    var recvDate: Date!
    
    @IBOutlet weak var confirmResultsModal: UIView?
    @IBOutlet weak var confirmResultsTextView: UITextView?
    @IBOutlet weak var confirmBtn: UIButton?
    @IBOutlet weak var backConfirmBtn: UIButton?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = startReportView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismiss(animated: true, completion: nil)
    }
    
    // Start report view functions
    @IBAction func startReportBtn() {
        // Goes to different view
        print("User understood report implication")
        testDate = Date()
        recvDate = Date()
        testDateBtn?.setTitle(testDate.string(), for: .normal)
        recvDateBtn?.setTitle(recvDate.string(), for: .normal)
        covidResultText?.text = "No"
        UIView.transition(from: startReportView!, to: inputResultsView!, duration: 0.5, options: [.transitionFlipFromRight], completion: { [self] _ in view = inputResultsView })
    }
    
    
    // Input results view functions
    @IBAction func covidResultSwitch(_ sender: UISwitch){
        if sender.isOn {
            covidResultText?.text = "Yes"
        } else {
            covidResultText?.text = "No"
        }
    }
    
    @IBAction func submitBtn(){
        if testDate > recvDate {
            print("User test date is later than received date")
            return
        }
        
        // Show confirm results prompt
        UIView.transition(with: confirmResultsModal!, duration: 0.5, options: [.transitionCrossDissolve], animations: { self.confirmResultsModal?.isHidden = false }, completion: nil)
        confirmResultsTextView?.text = "Test date: " + testDate.string()
        confirmResultsTextView?.text += "\nReceived date: " + recvDate.string()
        confirmResultsTextView?.text += "\nCovid-positive: " + (covidResultText?.text)!
    }
    
    @IBAction func DateButton(_ sender: UIButton) {
        let minDate = DatePickerHelper.shared.dateFrom(day: 18, month: 08, year: Date().year() - 1)!
        var maxDate = DatePickerHelper.shared.dateFrom(day: Date().day(), month: Date().month(), year: Date().year())!
        if sender == testDateBtn {
            maxDate = DatePickerHelper.shared.dateFrom(day: recvDate.day(), month: recvDate.month(), year: recvDate.year())!
        }
        let today = Date()
        let datePicker = DatePicker() // Create picker object
        
        // Setup
        datePicker.setup(beginWith: today, min: minDate, max: maxDate) { [self] (selected, date) in
            if selected, let selectedDate = date {
                print(selectedDate.string())
                if sender == testDateBtn {
                    testDateBtn?.setTitle(selectedDate.string(), for: .normal)
                    testDate = selectedDate
                } else {
                    recvDateBtn?.setTitle(selectedDate.string(), for: .normal)
                    recvDate = selectedDate
                }
            } else {
                print("Cancelled")
            }
        }
        
        // Display
        datePicker.show(in: self, on: sender)
    }
    
    
    // Confirm results modal view functions
    @IBAction func confirmResultBtn(_ sender: UIButton){
        confirmResultsModal?.isHidden = true
        
        if sender == confirmBtn {
            print("User confirms details")
            // Goes to camera
        }
    }
}

extension CALayer {
    var borderColorFromUIColor: UIColor {
        get {
            return UIColor(cgColor: self.borderColor!)
        } set {
            self.borderColor = newValue.cgColor
        }
    }
}
