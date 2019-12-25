//
//  MMVideoCaptureProgressView.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit

class MMVideoCaptureProgressView: UIView {
    // range : 0 ~ 1
    var value : CGFloat  = 0 {
        didSet{
            guard  value >= 0 , value <= 1 else { return value = 0 }
            self.circleLayer.strokeEnd = value
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        circleLayer.frame = self.bounds
        let rect = self.bounds.inset(by: UIEdgeInsets.init(top: circleLayer.lineWidth, left: circleLayer.lineWidth, bottom: circleLayer.lineWidth, right: circleLayer.lineWidth))
        let path = UIBezierPath.init(roundedRect: rect, cornerRadius: rect.width / 2)
        self.circleLayer.path = path.cgPath
    }
    private lazy var circleLayer : CAShapeLayer = {
        let layer = CAShapeLayer.init()
        layer.frame = self.bounds
        layer.lineWidth = 10
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.init(red: 48.0 / 255.0, green: 219.0 / 255.0, blue: 24.0 / 255.0, alpha: 1) .cgColor
        layer.strokeStart = 0
        layer.strokeEnd = 0
        self.layer.addSublayer(layer)
        return layer
    }()
}
