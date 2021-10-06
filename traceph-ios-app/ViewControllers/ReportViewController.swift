//
//  ReportViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 7/27/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit
import DatePicker
import AVFoundation

class ReportViewController: UIViewController {
    // Data to be sent to server
    var testDate: Date!
    var recvDate: Date!
    var covidResult: Bool!
    var qrCode: String!
    
    // Start report view (Implication of report) Outlet
    @IBOutlet weak var startReportView: UIView?
    @IBOutlet weak var reportHeaderView: UIImageView!
    
    // Input results view Outlets
    @IBOutlet weak var inputResultsView: UIView?
    @IBOutlet weak var testDateBtn: UIButton?
    @IBOutlet weak var recvDateBtn: UIButton?
    @IBOutlet weak var covidResultSwitch: UISwitch?
    @IBOutlet weak var covidResultText: UILabel?
    
    // Confirm results modal Outlets
    @IBOutlet weak var confirmResultsModal: UIView?
    @IBOutlet weak var confirmResultsTextView: UITextView?
    @IBOutlet weak var confirmBtn: UIButton?
    @IBOutlet weak var backConfirmBtn: UIButton?
    
    // QR scanner view Outlets
    @IBOutlet weak var qrScanView: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    // Auth code view Outlets
    @IBOutlet weak var inputTokenView: UIView?
    @IBOutlet weak var authCodeModalView: UIView?
    @IBOutlet weak var authCodeTextView: UITextView?
    @IBOutlet weak var authCodeTextField: UITextField?
    @IBOutlet weak var authCodeBtn: UIButton?
    
    // Verdict view Outlets
    @IBOutlet weak var verdictView: UIView?
    @IBOutlet weak var verdictTextView: UITextView?
    
    
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
        print("User understood report implication")
        
        // Initialize variables
        testDate = Date()
        recvDate = Date()
        testDateBtn?.setTitle(testDate.string(), for: .normal)
        recvDateBtn?.setTitle(recvDate.string(), for: .normal)
        covidResultText?.text = "No"
        covidResult = false
        
        // Change views and disables menu button
        // Disabling the menu button means the user has no choice but to finish the report
        // They can go back by pressing the back button
        UIView.transition(from: startReportView!, to: inputResultsView!, duration: 0.5, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [self] _ in inputResultsView?.isHidden = false; view = inputResultsView; navigationController?.navigationBar.isHidden = true })
    }
    
    
    // Input results view functions
    @IBAction func covidResultSwitchPress(_ sender: UISwitch){
        if sender.isOn {
            covidResultText?.text = "Yes"
            covidResult = true
        } else {
            covidResultText?.text = "No"
            covidResult = false
        }
    }
    
    @IBAction func submitBtn(){
        if testDate > recvDate {
            let dateAlert = UIAlertController(title: "Test date error", message: "Your test date is later than when you receive the test results. Please input the correct dates.", preferredStyle: .alert)
            dateAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(dateAlert, animated: true, completion: nil)
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
    
    @IBAction func inputBackBtn(){
        UIView.transition(from: inputResultsView!, to: startReportView!, duration: 0.5, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [self] _ in inputResultsView?.isHidden = true; view = startReportView; navigationController?.navigationBar.isHidden = false })
    }
    
    
    // Confirm results modal view functions
    @IBAction func confirmResultBtn(_ sender: UIButton){
        confirmResultsModal?.isHidden = true
        
        if sender == confirmBtn {
            print("User confirms details")
            
            // Get camera permission access
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
                if response {
                    print("Camera access accepted")
                } else {
                    print("Camera access declined")
                }
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(didGetQRCode(_:)), name: Notification.Name("QRcode"), object: nil)
        }
    }
    
    @objc func didGetQRCode(_ notification: Notification){
        qrCode = notification.object as! String?
//        print("QR code:", qrCode!)
        
        qrScanView?.isHidden = false
        view = qrScanView
        activityIndicator?.startAnimating()
        
        // Get authentication code
        APIController.sourceNodeID.onSucceed(){ [self] nodeID in
            ReportAPI().getToken(nodeID: nodeID, data: qrCode)
            .onSucceed { [self] result in
                print(result)
                authCodeTextView?.text = result
                counterTimer = 30
                countDown()
                UIView.transition(from: qrScanView!, to: inputTokenView!, duration: 1, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [self] _ in qrScanView?.isHidden = true; authCodeModalView?.isHidden = false; view = inputTokenView })
            }
            
            ReportAPI().getToken(nodeID: nodeID, data: qrCode)
            .onFail { [self] result in
                print(result)
                // Status code 400:
                // Either caused by broken QR or scanning of non-DetectPH QR
                verdictTextView?.text = "Sorry but your report could not be made. It's possible that you may have reported before or your QR code is broken."
                UIView.transition(from: qrScanView!, to: verdictView!, duration: 1, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [self] _ in qrScanView?.isHidden = true; view = verdictView })
            }
        }
    }
    
    
    // Authentication code view functions
    @IBAction func authCodeBtnPress(){
        UIView.transition(with: authCodeModalView!, duration: 0.5, options: [.transitionCrossDissolve], animations: { self.authCodeModalView?.isHidden = true }, completion: nil)
    }
    
    // Starts countdown timer of auth code button
    var counterTimer: Int!
    func countDown(){
//        print("Current count: \(counterTimer ?? 30)")
        if authCodeModalView?.isHidden == true {
            return
        }
        
        if counterTimer < 0 {
            UIView.transition(with: authCodeModalView!, duration: 0.5, options: [.transitionCrossDissolve], animations: { self.authCodeModalView?.isHidden = true }, completion: nil)
        } else {
            authCodeBtn?.setTitle("Ok (\(counterTimer ?? 30))", for: .normal)
            counterTimer = counterTimer - 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { self.countDown() })
        }
        
        return
    }
    
    // Send to API for auth code checking
    // If okay, go to verdict screen and updated verdict text
    @IBAction func authCodeConfirm(){
        let code = (authCodeTextField?.text)!
        // Shows error prompt if auth code is not 6 numbers
        if code.count != 6 || !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: code)){
            let authCodeAlert = UIAlertController(title: "Authentication code", message: "You must input 6 numbers", preferredStyle: .alert)
            authCodeAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(authCodeAlert, animated: true, completion: nil)
            return
        }
        
        APIController.sourceNodeID.onSucceed(){ [self] nodeID in
            ReportAPI().sendReport(
                nodeID: nodeID,
                authCode: code,
                data: qrCode,
                info: ReportAPI.patient_info(
                    test_result: covidResult, test_result_date: recvDate, reference_date: testDate))
            .onSucceed { [self] result in
                switch result {
                    case "wrong":
                        verdictTextView?.text = "Wrong input code."
                    case "expired":
                        verdictTextView?.text = "Sorry but your report could not be made. Your QR code is expired."
                    case "denied":
                        verdictTextView?.text = "Sorry but your report could not be made. This QR code has already been reported."
                    case "accepted":
                        verdictTextView?.text = "Report accepted."
                    default:
                        verdictTextView?.text = "Sorry but your report could not be made. It's possible that you may have reported before or your QR code is broken."
                }
                
                
                UIView.transition(from: inputTokenView!, to: verdictView!, duration: 0.5, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [self] _ in inputTokenView?.isHidden = true; view = verdictView })
            }
        }
    }
    
    
    // Report verdict view functions
    @IBAction func verdictOkPress(){        // Comes full circle
        UIView.transition(from: verdictView!, to: startReportView!, duration: 0.5, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [self] _ in verdictView?.isHidden = true; view = startReportView; navigationController?.navigationBar.isHidden = false })
    }
}
