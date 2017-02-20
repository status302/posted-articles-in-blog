//
//  ScanViewController.swift
//  YLQRCode
//
//  Created by yolo on 2017/1/1.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//
//  仅仅是视图和扫描的作用
//

import UIKit
import AVFoundation
import CoreImage
import SafariServices

enum YLScanSetupResult {
    case successed
    case failed
    case unknown
}

class QRScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    fileprivate var captureSession = AVCaptureSession()

    fileprivate var capturePreviewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var deviceInput: AVCaptureDeviceInput?
    fileprivate var metadataOutput: AVCaptureMetadataOutput?
    fileprivate var dimmingView: DimmingView?
    
    fileprivate var rectOfInteres = CGRect.zero
    
    fileprivate var sessionQueue = DispatchQueue(label: "com.vsccw.qrcode.session.queue", attributes: [], target: nil)
    
    fileprivate var setupResult = YLScanSetupResult.successed
    
    fileprivate var isFirstPush = false
    
    fileprivate var activityView: UIActivityIndicatorView?
    
    var style: ScanViewConfig?
    fileprivate var selectPhotosButton: UIButton!
    
    /// 得到的二维码String信息 去override
    var resultString: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        isFirstPush = true
        view.backgroundColor = UIColor.black
        
        func authorizationStatus() -> YLScanSetupResult {
            var setupResult = YLScanSetupResult.successed
            let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            switch authorizationStatus {
            case .authorized:
                setupResult = YLScanSetupResult.successed
            case .notDetermined:
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [weak self] (granted) in
                    if !granted {
                        setupResult = YLScanSetupResult.failed
                    }
                    self?.sessionQueue.resume()
                })
                break
            case .denied:
                setupResult = YLScanSetupResult.failed
                break
            default:
                setupResult = YLScanSetupResult.unknown
                break
            }
            return setupResult
        }
        
        setupResult = authorizationStatus()
        dimmingView = DimmingView(frame: view.bounds)

        let viewStyle = dimmingView!.style
        
        let viewWidth = view.frame.width
        let viewHeight = view.frame.height

        let objectiveyY = ((viewHeight - viewStyle.scanRectWidthHeight) * 0.5 - viewStyle.contentOffSetUp + 64.0) / viewHeight
        let objectiveX = (viewWidth - viewStyle.scanRectWidthHeight) * 0.5 / viewWidth
        let objectiveHeight = viewStyle.scanRectWidthHeight / viewHeight
        let objectiveWidth = viewStyle.scanRectWidthHeight / viewWidth
        
        rectOfInteres = CGRect(x: objectiveyY,
                               y: objectiveX,
                               width: objectiveHeight,
                               height: objectiveWidth)
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView?.tintColor = UIColor.black
        activityView?.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        activityView?.center = CGPoint(x: view.center.x, y: view.center.y - 100)
        activityView?.hidesWhenStopped = true
        view.addSubview(activityView!)
        activityView?.startAnimating()

        selectPhotosButton = UIButton(frame: CGRect(x: 35.0, y: viewHeight - 136.0, width: UIScreen.main.bounds.width - 70.0, height: 44.0))
        selectPhotosButton.layer.masksToBounds = true
        selectPhotosButton.layer.cornerRadius = 4.0
        selectPhotosButton.backgroundColor = UIColor.yellow
        selectPhotosButton.setTitle("扫描相册中的二维码", for: UIControlState())
        selectPhotosButton.setTitleColor(UIColor.black, for: .normal)
        selectPhotosButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        selectPhotosButton.addTarget(self, action: #selector(openAlbumAction(_:)), for: .touchUpInside)

        /// 在一个新的队列里进行初始化工作，还是**主线程**
        sessionQueue.sync { [weak self] in
            self?.configSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sessionQueue.sync { [weak self] in
            guard let strongSelf = self else { return }
            switch strongSelf.setupResult {
            case .successed:
                strongSelf.activityView?.stopAnimating()
                strongSelf.view.addSubview(strongSelf.dimmingView!)
                strongSelf.view.addSubview(strongSelf.selectPhotosButton)
                if strongSelf.isFirstPush {
                    strongSelf.startSessionRunning()
                }
            default:
                strongSelf.activityView?.stopAnimating()
                let message = "没有权限获取相机"
                let	alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "设置", style: .`default`, handler: { action in
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                }))
                strongSelf.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSessionRunning()
    }

    func startSessionRunning() {
        captureSession.startRunning()
        dimmingView?.beginAnimation()
    }

    func stopSessionRunning() {
        captureSession.stopRunning()
        DispatchQueue.safeMainQueue { [weak self] in
            self?.dimmingView?.removeAnimations()
        }
    }

    private func configSession() {
        
        if setupResult != .successed {
            return
        }
        
        /// setup session
        captureSession.beginConfiguration()
        
        do {
            var defaultVedioDevice: AVCaptureDevice?
            
            if #available(iOS 10.0, *) {
                if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
                    defaultVedioDevice = backCameraDevice
                }
                else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                    defaultVedioDevice = frontCameraDevice
                }
            }
            else {
                if let cameraDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) {
                    defaultVedioDevice = cameraDevice
                }
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVedioDevice)
            
            /// 添加自动对焦功能，否则不容易读取二维码
            /// **添加了自动对焦，反而增大了模糊误差**
//            if videoDeviceInput.device.isAutoFocusRangeRestrictionSupported
//                && videoDeviceInput.device.isSmoothAutoFocusSupported {
//                try videoDeviceInput.device.lockForConfiguration()
//                videoDeviceInput.device.focusMode = .autoFocus
//                videoDeviceInput.device.unlockForConfiguration()
//            }

            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
            self.deviceInput = videoDeviceInput
        }
        catch {
            print("无法添加input.")
            setupResult = .failed
        }
        metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
        }
        else {
            setupResult = .failed
            return
        }
        metadataOutput?.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
        metadataOutput?.metadataObjectTypes = metadataOutput?.availableMetadataObjectTypes
        metadataOutput?.rectOfInterest = self.rectOfInteres
        
        captureSession.commitConfiguration()
        
        capturePreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        capturePreviewLayer?.frame = view.bounds
        view.layer.insertSublayer(capturePreviewLayer!, at: 0)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        for _supportedBarcode in metadataObjects {
           
            guard let supportedBarcode = _supportedBarcode as? AVMetadataObject else { return }
            
            if supportedBarcode.type == AVMetadataObjectTypeQRCode {
                guard let barcodeObject = self.capturePreviewLayer?.transformedMetadataObject(for: supportedBarcode) as? AVMetadataMachineReadableCodeObject else { return }
                self.stopSessionRunning()
                QRScanCommon.playSound()
                self.resultString = barcodeObject.stringValue
                return
            }
        }
    }

    func openAlbumAction(_ sender: Any) {
        self.stopSessionRunning()
        isFirstPush = false
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerView = UIImagePickerController()
            imagePickerView.allowsEditing = false
            imagePickerView.sourceType = .photoLibrary
            imagePickerView.delegate = self
            present(imagePickerView, animated: true, completion: nil)
        }
    }
}

extension QRScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isFirstPush = true
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)

        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            YLDetectQRCode.scanQRCodeFromPhotoLibrary(image: image) { [weak self] str in
                if let result = str {
                    self?.resultString = result
                    QRScanCommon.playSound()
                }
                else {
                    self?.isFirstPush = false
                    let alertView = UIAlertView(title: "提醒", message: "没有二维码", delegate: nil, cancelButtonTitle: "取消", otherButtonTitles: "确定")
                    alertView.show()
                }
            }
        }
    }
}
