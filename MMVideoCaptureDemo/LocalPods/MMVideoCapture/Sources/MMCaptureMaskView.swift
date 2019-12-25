//
//  MMCaptureMaskView.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit

class MMCaptureMaskView: UIView {

    private let gradient = CAGradientLayer()
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init(with frame:CGRect, gradientColors: [CGColor] = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor], startPoint : CGPoint = CGPoint(x: 0, y: 0), endPoint : CGPoint = CGPoint(x: 0, y: 1)) {
        super.init(frame: frame)
        self.setup(with: gradientColors, startPoint: startPoint, endPoint: endPoint)
    }
    
    private func setup(with gradientColors: [CGColor] = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor], startPoint : CGPoint = CGPoint(x: 0, y: 0), endPoint : CGPoint = CGPoint(x: 0, y: 1)){
        gradient.colors = gradientColors
        gradient.frame = self.bounds
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        self.layer.addSublayer(gradient)
        self.isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
//        gradient.frame = self.bounds
    }
}
