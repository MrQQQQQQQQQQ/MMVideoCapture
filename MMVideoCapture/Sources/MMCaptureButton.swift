//
//  MMCaptureButton.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit
import SnapKit

protocol MMCaptureButtonDelegate : NSObjectProtocol {
    func captureButtonPressed(button : MMCaptureButton)
    func captureButtonLongPressed(button : MMCaptureButton , began : Bool)
    func captureButtonLongPressed(button: MMCaptureButton,zoomingLevel:CGFloat)
}

class MMButton: UIButton {
    fileprivate var oriBackgroundColor: UIColor?
     fileprivate var customHilightTitleColor: Bool = false
     fileprivate var customHilightImage: Bool = false
     fileprivate var customHightlighted: Bool = true
     fileprivate var disableAlpha: CGFloat = 0.2
    fileprivate let hilightDefualtAlpha : CGFloat = 0.8
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.adjustsImageWhenHighlighted = false
        self.adjustsImageWhenDisabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override var isHighlighted: Bool {
         willSet {
             if customHightlighted {
                 if isHighlighted {
                     if backgroundColor != nil {
                         if oriBackgroundColor == nil {
                             oriBackgroundColor = backgroundColor
                         }
                         super.backgroundColor = backgroundColor?.withAlphaComponent(hilightDefualtAlpha)
                     }
                     if customHilightTitleColor == false {
                         let normalColor = titleColor(for: .normal)
                         var alpha: CGFloat = 0
                         normalColor?.getRed(nil, green: nil, blue: nil, alpha: &alpha)
                         setTitleColor(normalColor?.withAlphaComponent(alpha * hilightDefualtAlpha), for: .highlighted)
                     }
                     if customHilightImage == false {
                         if let img = image(for: .normal) {
                             setImage(MMimageByApplyingAlpha(hilightDefualtAlpha, img), for: .highlighted)
                         }
                     }
                     if self.layer.borderColor != nil {
                         self.layer.borderColor = UIColor.init(cgColor: self.layer.borderColor!).withAlphaComponent(hilightDefualtAlpha).cgColor
                     }
                 } else {
                     if oriBackgroundColor != nil {
                         super.backgroundColor = oriBackgroundColor
                         oriBackgroundColor = nil
                     }
                     if self.layer.borderColor != nil {
                         self.layer.borderColor = UIColor.init(cgColor: self.layer.borderColor!).withAlphaComponent(1).cgColor
                     }
                 }
             }else {
                 
             }
         }
     }
     
     override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
         if state == .highlighted {
             customHilightTitleColor = color != nil
         }
         super.setTitleColor(color, for: state)
     }
     
     override func setImage(_ image: UIImage?, for state: UIControl.State) {
         if state == .highlighted {
             customHilightImage = image != nil
         }
         super.setImage(image, for: state)
     }

     override var isEnabled: Bool {
         willSet {
             if newValue {
                 self.alpha = 1.0
             }else {
                 self.alpha = self.disableAlpha
             }
         }
     }
}

class MMCaptureButton: UIView {
    weak var delegate : MMCaptureButtonDelegate?
    private let blurView = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .light))
    private var progressTimer  : Timer? = nil
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let blur_w = self.bounds.width - 20
        self.blurView.frame = CGRect.init(x: 0, y: 0, width: blur_w, height: blur_w)
        self.blurView.center = CGPoint.init(x: self.bounds.width / 2, y: self.bounds.height / 2)
        self.blurView.layer.cornerRadius = blur_w / 2
        self.blurView.layer.masksToBounds = true
        self.layer.cornerRadius = self.bounds.width / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setup(){
        self.backgroundColor = .clear
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 4
        addSubview(self.blurView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPress.minimumPressDuration = 0.3
        addGestureRecognizer(tap)
        addGestureRecognizer(longPress)
    }
    
    private var lastTapTime = NSDate().timeIntervalSince1970
    @objc private func tap(_ ges:UITapGestureRecognizer){
        let now = NSDate().timeIntervalSince1970
        if now - lastTapTime < 1 { // 限制一秒只响应一次
            return
        }
        lastTapTime = now
        if let del = delegate {
            del.captureButtonPressed(button: self)
        }
    }
    
    @objc private func longPress(_ ges:UILongPressGestureRecognizer){
        print("state is \(ges.state)")
        guard let del = delegate else { return  }
        switch ges.state {
        case .began:
            del.captureButtonLongPressed(button: self, began: true)
            break
        case .changed:
            let maxDistance : CGFloat = UIScreen.main.bounds.height * 0.8
            let location = ges.location(in: self)
            print("location is \(location)")
            if location.y > 0{ // 在圈内移动不处理
                del.captureButtonLongPressed(button: self, zoomingLevel: 0)
                break
            }
            let zoomLevel = max( min((-location.y) / maxDistance , 1) , 0)
            del.captureButtonLongPressed(button: self, zoomingLevel: zoomLevel)
        default:
            del.captureButtonLongPressed(button: self, began: false)
            break
        }
    }
}
