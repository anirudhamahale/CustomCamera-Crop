//
//  CameraViewController.swift
//  CustomCameraView
//
//  Created by Anirudha on 15/03/18.
//  Copyright © 2018 Anirudha Mahale. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    @IBOutlet weak var guideImageView: UIImageView!
    @IBOutlet weak var guidesView: UIView!
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var cameraButtonView: UIView!
    
    @IBOutlet weak var captureButton: UIButton!
    
    var captureSession = AVCaptureSession()
    var previewLayer: CALayer!
    var captureDevice: AVCaptureDevice!
    
    /// This will be true when the user clicks on the click photo button.
    var takePhoto = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        previewLayer = CALayer()
        takePhoto = false
        
        requestAuthorization()
    }

    private func userinteractionToButton(_ interaction: Bool) {
        captureButton.isEnabled = interaction
    }
    
    /// This function will request authorization, If authorized then start the camera.
    private func requestAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            prepareCamera()
            
        case .denied, .restricted, .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if !Thread.isMainThread {
                    DispatchQueue.main.async {
                        if granted {
                            self.prepareCamera()
                        } else {
                            let alert = UIAlertController(title: "unable_to_access_the_Camera", message: "to_enable_access_go_to_setting_privacy_camera_and_turn_on_camera_access_for_this_app", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: {_ in
                                self.navigationController?.popToRootViewController(animated: true)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                } else {
                    if granted {
                        self.prepareCamera()
                    } else {
                        let alert = UIAlertController(title: "unable_to_access_the_Camera", message: "to_enable_access_go_to_setting_privacy_camera_and_turn_on_camera_access_for_this_app", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: {_ in
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            })
        }
    }
    
    /// Will see if the primary camera is avilable, If found will call method which will asign the available device to the AVCaptureDevice.
    private func prepareCamera() {
        // Resets the session.
        self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        if #available(iOS 10.0, *) {
            let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
            assignCamera(availableDevices)
        } else {
            // Fallback on earlier versions
            // development, need to test this on iOS 8
            if let availableDevices = AVCaptureDevice.default(for: AVMediaType.video) {
                assignCamera([availableDevices])
            } else {
                showAlert()
            }
        }
    }
    
    /// Assigns AVCaptureDevice to the respected the variable, will begin the session.
    ///
    /// - Parameter availableDevices: [AVCaptureDevice]
    private func assignCamera(_ availableDevices: [AVCaptureDevice]) {
        if availableDevices.first != nil {
            captureDevice = availableDevices.first
            beginSession()
        } else {
            showAlert()
        }
    }
    
    /// Configures the camera settings and begins the session, this function will be responsible for showing the image on the UI.
    private func beginSession() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error.localizedDescription)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewView.layer.addSublayer(previewLayer)
        previewLayer.frame = view.layer.frame
        previewLayer.frame.origin.y = +cameraPreviewView.frame.origin.y
        (previewLayer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.masksToBounds = true
        cameraPreviewView.clipsToBounds = true
        captureSession.startRunning()
    
        view.bringSubview(toFront: cameraPreviewView)
        view.bringSubview(toFront: cameraButtonView)
        view.bringSubview(toFront: guidesView)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String):NSNumber(value:kCVPixelFormatType_32BGRA)]
        
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        captureSession.commitConfiguration()
        
        let queue = DispatchQueue(label: "com.letsappit.camera")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        self.userinteractionToButton(true)
    }
    
    
    /// Get the UIImage from the given CMSampleBuffer.
    ///
    /// - Parameter buffer: CMSampleBuffer
    /// - Returns: UIImage?
    func getImageFromSampleBuffer(buffer:CMSampleBuffer, orientation: UIImageOrientation) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: orientation)
                
            }
            
        }
        return nil
    }
    
    /// This function will destroy the capture session.
    func stopCaptureSession() {
        captureSession.stopRunning()
        
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession.removeInput(input)
            }
        }
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Unable to access the camera", message: "It appears that either your device doesn't have camera or its broken", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: {_ in
            self.navigationController?.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didTapClick(_ sender: Any) {
        userinteractionToButton(false)
        takePhoto = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImage" {
            let vc = segue.destination as! ShowImageViewController
            vc.image = sender as! UIImage
        }
    }
    
    func takeScreenShot() -> UIImage {
        previewLayer.setNeedsDisplay()
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        view.layer.render(in: context)
        previewLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        if takePhoto {
            takePhoto = false
            
            // Rotation should be unlocked to work.
            var orientation = UIImageOrientation.up
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                orientation = .left
                
            case .landscapeRight:
                orientation = .right
                
            case .portraitUpsideDown:
                orientation = .down
                
            default:
                orientation = .up
            }
            
            DispatchQueue.main.async {
                let newImage = self.takeScreenShot()
                
                // let newImage = image.imageByCropToRect(rect: self.guideImageView.frame, scale: true)
                self.stopCaptureSession()
                self.previewLayer.removeFromSuperlayer()
                self.performSegue(withIdentifier: "showImage", sender: newImage)
            }
        }
    }
}
