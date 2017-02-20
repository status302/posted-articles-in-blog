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
            let alertView = UIAlertView(title: "提醒", message: "找不到音频文件", delegate: nil, cancelButtonTitle: "取消", otherButtonTitles: "确定")
            alertView.show()
            return
        }
        let soundURL = URL(fileURLWithPath: filePath)
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        
        AudioServicesPlaySystemSound(soundID)
        AudioServicesRemoveSystemSoundCompletion(soundID)
    }
}
