//
//  YLQRCodeScanViewController.swift
//  YLQRCode
//
//  Created by yolo on 2017/2/4.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//

import UIKit
import SafariServices

class ResultViewController : QRScanViewController {

    override var resultString: String? {
        didSet {
            DispatchQueue.safeMainQueue { [weak self] in
                if let result = self?.resultString {
                    if result.hasPrefix("http") {
                        if let url = URL.init(string: result) {
                            let sfViewController = SFSafariViewController(url: url)
                            self?.present(sfViewController, animated: true, completion: nil)
                        }
                    }
                    else {
                        let alertView = UIAlertView.init(title: "二维码结果", message: result, delegate: nil, cancelButtonTitle: "确定")
                        alertView.show()
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
