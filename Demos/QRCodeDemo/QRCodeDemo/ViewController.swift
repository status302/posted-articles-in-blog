//
//  ViewController.swift
//  YLQRCode
//
//  Created by yolo on 2017/1/1.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//

import UIKit
import SafariServices

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
        guard gesture.state == .began else { return }
        
        let detect: ((UIAlertAction) -> Void)? = { [weak self] _ in
            guard let image = self?.imageView.image else { return }
            YLDetectQRCode.scanQRCodeFromPhotoLibrary(image: image) { (result) in
                guard let _result = result else { return }
                QRScanCommon.playSound()
                if _result.hasPrefix("http") {
                    if let url = URL.init(string: _result) {
                        let sfVC = SFSafariViewController(url: url)
                        self?.present(sfVC, animated: true, completion: nil)
                    }
                }
                else {
                    showAlertView(title: "二维码结果", message: _result, cancelButtonTitle: "确定")
                }
            }
        }

        let saveQRCode: ((UIAlertAction) -> Void)? = { [weak self] _ in
            guard let image = self?.imageView.image else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(ViewController.image(image:error:contextInfo:)), nil)
        }
        
        let alertController = UIAlertController(title: "请选择", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "识别二维码", style: .default, handler: detect))
        alertController.addAction(UIAlertAction.init(title: "保存二维码", style: .default, handler: saveQRCode))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
       
    }

    //  - (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
    func image(image: UIImage, error: Error, contextInfo: Any) {
        showAlertView(title: "提醒", message: "保存图片成功", cancelButtonTitle: "确定")
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

