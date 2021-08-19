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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = startReportView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startReportBtn() {
        // Goes to different view
        print("User understood report implication")
        view = inputResultsView
        testDate = Date()
        recvDate = Date()
        testDateBtn?.setTitle(testDate.string(), for: .normal)
        recvDateBtn?.setTitle(recvDate.string(), for: .normal)
        covidResultText?.text = "No"
    }
    
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
        
        print("User inputs the following")
        print("Test date: " + testDate.string())
        print("Received date: " + recvDate.string())
        print("Covid-positive: " + (covidResultText?.text)!)
        // Show confirm results prompt
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
}
