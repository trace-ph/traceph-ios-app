//
//  QRScannerViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 8/26/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit
import AVFoundation

@available(iOS 13.0, *)
class QRScannerViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var galleryIcon: UIButton!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera, .builtInTrueDepthCamera, .builtInUltraWideCamera, .builtInDualWideCamera], mediaType: AVMediaType.video, position: .back)

        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }

        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)

            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture.
            captureSession.startRunning()
            
            // Move the top bar to the front
            view.bringSubviewToFront(topBar)

        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }

    @IBAction func unwindToHomeScreen(segue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func galleryBtn(){
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Opening gallery")

            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
        }
    }
    
}

@available(iOS 13.0, *)
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds

            if metadataObj.stringValue != nil {
                captureSession.stopRunning()    // Freeze camera
//                print(metadataObj.stringValue!)

                // Send qr code to Report view controller
                NotificationCenter.default.post(name: Notification.Name("QRcode"), object: metadataObj.stringValue!)

                dismiss(animated: true, completion: nil)    // Close segue
            }
        }
    }
}

@available(iOS 13.0, *)
extension QRScannerViewController: UIImagePickerControllerDelegate {
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("Picking image done")
        
        // Initialize QR code detector and image to be detected
        if let qrcodeImg = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            let ciImage: CIImage = CIImage(image:qrcodeImg)!
            let decoderOptions = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            
            // Decode QR code
            var qrCodeLink = ""
            let features = detector.features(in: ciImage, options: decoderOptions)
            for case let feature as CIQRCodeFeature in features {
                qrCodeLink += feature.messageString!
                print(feature.messageString!)
            }

            if qrCodeLink == "" {
                print("nothing")
            } else {
                print("message: \(qrCodeLink)")
            }
            // Send qr code to Report view controller
            NotificationCenter.default.post(name: Notification.Name("QRcode"), object: qrCodeLink)
            dismiss(animated: true, completion: nil)
        } else {
            print("Something went wrong")
            // Send empty string to Report view controller
            NotificationCenter.default.post(name: Notification.Name("QRcode"), object: "")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Picker is canceled")
        picker.dismiss(animated: true, completion: nil)
    }
}

// Reference:
// https://medium.com/appcoda-tutorials/how-to-build-qr-code-scanner-app-in-swift-b5532406dd6b
