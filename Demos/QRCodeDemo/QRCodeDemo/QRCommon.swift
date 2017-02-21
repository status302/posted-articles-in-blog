//
//  YLCommon.swift
//  YLQRCode
//
//  Created by yolo on 2017/1/1.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//

import UIKit
import AudioToolbox

extension DispatchQueue {
    static func safeMainQueue(block: @escaping () -> Void) {
        if !Thread.isMainThread {
            DispatchQueue.main.async(execute: block)
        } else {
            block()
        }
    }
}

struct QRScanCommon {
    static func playSound() {
        guard let filePath = Bundle.main.path(forResource: "qrcode_found", ofType: "wav") else {
            showAlertView(title: "提醒", message: "找不到音频文件", cancelButtonTitle: "确定")
            return
        }
        let soundURL = URL(fileURLWithPath: filePath)
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        
        AudioServicesPlaySystemSound(soundID)
        AudioServicesRemoveSystemSoundCompletion(soundID)
    }
}

func showAlertView(title: String, message: String, cancelButtonTitle: String) {
    let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(UIAlertAction.init(title: cancelButtonTitle, style: .cancel, handler: nil))
    UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
}
