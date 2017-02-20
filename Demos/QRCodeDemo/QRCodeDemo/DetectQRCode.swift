//
//  DetectQRCode.swift
//  YLQRCode
//
//  Created by yolo on 2017/1/20.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//

import UIKit
import CoreImage

typealias CompletionHandler<T> = (T) -> Void

struct YLDetectQRCode {
    static func scanQRCodeFromPhotoLibrary(image: UIImage, completion: CompletionHandler<String?>) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        if let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) {
            let features = detector.features(in: CIImage(cgImage: cgImage))
            for feature in features { // 这里实际上可以识别两张二维码，在这里只取第一张（左边或者上边）
                if let qrFeature = feature as? CIQRCodeFeature {
                    completion(qrFeature.messageString)
                    return
                }
            }
        }
        completion(nil)
    }
}
