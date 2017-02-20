//
//  DimmingView.swift
//  YLQRCode
//
//  Created by yolo on 2017/1/18.
//  Copyright © 2017年 Qiuncheng. All rights reserved.
//

import UIKit

internal struct ScanViewConfig {
    var contentOffSetUp: CGFloat = 64.0 + 80.0
    var scanRectWidthHeight: CGFloat = 475.0 * 0.5
    var borderLineColor: UIColor = UIColor.yellow
    
    var borderLineWidth: CGFloat = 4.0
    
}

internal class DimmingView: UIView {
    
    fileprivate var rectOfInteract = CGRect.zero
    
    private var imageView: UIImageView!
    private var animatableView: UIImageView!
    private var _style: ScanViewConfig!
    
    private let animatedViewKey = "moveView.transform.translation.y"
    
    internal var style: ScanViewConfig {
        return _style
    }
    
    convenience init(frame: CGRect, style: ScanViewConfig = ScanViewConfig()) {
        self.init(frame: frame)
        let viewWidth = frame.width
        
        _style = style
        
        rectOfInteract = CGRect(x: (viewWidth - style.scanRectWidthHeight) * 0.5,
                                y: style.contentOffSetUp,
                                width: style.scanRectWidthHeight,
                                height: style.scanRectWidthHeight)
        setup()
    }

    private override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    private func setup() {
        let imageView = UIImageView()
        imageView.frame = rectOfInteract
        imageView.image = #imageLiteral(resourceName: "Border")
        addSubview(imageView)
        self.imageView = imageView
        
        let animatableView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageView.frame.width, height: 1))
        animatableView.image = #imageLiteral(resourceName: "ScanLineImage")
        animatableView.isHidden = true
        imageView.addSubview(animatableView)
        self.animatableView = animatableView
        
        let imageViewOriginX = imageView.frame.origin.x
        let imageViewOriginY = imageView.frame.origin.y
        let imageViewHeight = imageView.frame.height
        let imageViewWidth = imageView.frame.width
        
        let leftLayer = CALayer()
        leftLayer.frame = CGRect(x: 0, y: 0, width: imageViewOriginX, height: frame.height)
        leftLayer.backgroundColor = UIColor(white: 0.0, alpha: 0.92).cgColor
        layer.addSublayer(leftLayer)
        
        let topLayer = CALayer()
        topLayer.frame = CGRect(x: imageViewOriginX, y: 0, width: frame.width - 2 * imageViewOriginX, height: imageViewOriginY)
        topLayer.backgroundColor = UIColor(white: 0.0, alpha: 0.92).cgColor
        layer.addSublayer(topLayer)
        
        let rightLayer = CALayer()
        rightLayer.frame = CGRect(x: imageViewOriginX + imageViewWidth, y: 0, width: imageViewOriginX, height: frame.height)
        rightLayer.backgroundColor = UIColor(white: 0.0, alpha: 0.92).cgColor
        layer.addSublayer(rightLayer)
        
        let bottomLayer = CALayer()
        bottomLayer.frame = CGRect(x: imageViewOriginX, y: imageViewOriginY + imageViewHeight, width: imageViewWidth, height: frame.height - imageViewOriginY - imageViewHeight)
        bottomLayer.backgroundColor = UIColor(white: 0.0, alpha: 0.92).cgColor
        layer.addSublayer(bottomLayer)
        
        let label = UILabel()
        label.text = "将二维码放入框中，即可自动扫描"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white
        label.frame = CGRect(x: 0, y: imageView.frame.maxY + 5.0, width: bounds.width, height: 30)
        label.textAlignment = .center
        addSubview(label)
    }
    
    func beginAnimation() {
        animatableView.isHidden = false
        guard animatableView.layer.animation(forKey: animatedViewKey) == nil else {
           return
        }
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = 0
        animation.toValue = imageView.frame.height
        animation.repeatCount = MAXFLOAT
        animation.duration = 3.0
        animatableView.layer.add(animation, forKey: animatedViewKey)
    }
    
    func removeAnimations() {
        animatableView.layer.removeAnimation(forKey: animatedViewKey)
        animatableView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
