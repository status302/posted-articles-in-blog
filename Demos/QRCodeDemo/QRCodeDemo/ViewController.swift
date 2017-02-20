//
//  ViewController.swift
//  YLQRCode
//
//  Created by yolo on 2017/1/1.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        textField.text = "http://weixin.qq.com/r/QkB8ZE7EuxPErQoH9xVQ"
        
        imageView.isUserInteractionEnabled = true
        
        let long = UILongPressGestureRecognizer(target: self, action: #selector(detecteQRCode(gesture:)))
        
        imageView.addGestureRecognizer(long)
        
        generateQRCodeButtonClicked(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func detecteQRCode(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        func detect() {
            guard let image = imageView.image else { return }
            YLDetectQRCode.scanQRCodeFromPhotoLibrary(image: image) { (result) in
                guard let _result = result else { return }
                QRScanCommon.playSound()
                print(_result)
            }
        }
        
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "识别二维码", style: .default, handler: { (action) in
            detect()
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
       
    }
    
    @IBAction func generateQRCodeButtonClicked(_ sender: Any?) {
        view.endEditing(true)
        guard let text = textField.text else {
            return
        }
        
        GenerateQRCode.beginGenerate(text: text) {
            guard let image  = $0 else { return }
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image
            }
        }
    }
}

