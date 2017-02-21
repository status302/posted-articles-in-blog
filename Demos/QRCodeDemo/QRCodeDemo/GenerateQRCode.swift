//
//  GenerateQRCode.swift
//  YLQRCode
//
//  Created by yolo on 2017/1/20.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//

import UIKit
import CoreImage

struct GenerateQRCode {
    static func beginGenerate(text: String, completion: CompletionHandler<UIImage?>) {
        let strData = text.data(using: .utf8)
        
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter?.setValue(strData, forKey: "inputMessage")
        qrFilter?.setValue("H", forKey: "inputCorrectionLevel")
//        let color0 = UIColor.black.cgColor
//        let color1 = UIColor(white: 0.5, alpha: 1.0).cgColor
//        let colorFilter = CIFilter(name: "CIFalseColor", withInputParameters: ["inputImage": qrFilter!.outputImage!,"inputColor0": CIColor(cgColor: color0) ,"inputColor1": CIColor(cgColor: color1)])
        
        if let ciImage = qrFilter?.outputImage {
        
            let size = CGSize(width: 260, height: 260)
            let context = CIContext.vs_context(options: nil)
            var cgImage = context.createCGImage(ciImage, from: ciImage.extent)
            
            UIGraphicsBeginImageContext(size)
            let cgContext = UIGraphicsGetCurrentContext()
            cgContext?.interpolationQuality = .none
            cgContext?.scaleBy(x: 1.0, y: -1.0)
            cgContext?.draw(cgImage!, in: cgContext!.boundingBoxOfClipPath)
            
            let image = GenerateQRCode.getBorderImage(image: #imageLiteral(resourceName: "29"))
            
            if let podfileCGImage = image?.cgImage {
                cgContext?.draw(podfileCGImage, in: cgContext!.boundingBoxOfClipPath.insetBy(dx: (size.width - 34.0) * 0.5, dy: (size.height - 34.0) * 0.5))
            }
            
            let codeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            completion(codeImage)
            cgImage = nil
            return
        }
        completion(nil)
    }
    
    static func getBorderImage(image: UIImage) -> UIImage? {
        
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2.0
        imageView.image = image
        
        var currentImage: UIImage? = nil
        UIGraphicsBeginImageContext(CGSize(width: 34.0, height: 34.0))
        if let context = UIGraphicsGetCurrentContext() {
            imageView.layer.render(in: context)
            currentImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return currentImage
    }
}
