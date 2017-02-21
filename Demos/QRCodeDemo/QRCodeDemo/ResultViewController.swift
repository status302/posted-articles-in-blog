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
                if let result = self?.resultString,
                    result.hasPrefix("http") {
                    self?.showSF(urlStr: result)
                }
                else {
                    showAlertView(title: "二维码结果", message: self?.resultString ?? "nil", cancelButtonTitle: "确定")
                }
            }
        }
    }

    func showSF(urlStr: String?) {
        guard let urlString = urlStr else {
            return
        }
        if let url = URL.init(string: urlString) {
            let viewController = SFSafariViewController(url: url)
            self.present(viewController, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
