//
//  MMPreviewBaseViewController.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit

class MMPreviewBaseViewController: UIViewController {
    let backButton : MMButton = MMButton(type: .custom)
    let confirmButton : MMButton = MMButton(type: .custom)
    let backTitle : UILabel = UILabel()
    let confirmTitle : UILabel = UILabel()
    private let blurView = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .light))
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    func loadUI() {
        let kSafeBottomMargin = MMsafeAreaInsets().bottom
        self.view.backgroundColor = .black
        self.transitioningDelegate = self
        let layerView = UIView()
        layerView.frame = CGRect(x: 0, y: view.bounds.height - 140 - kSafeBottomMargin, width: self.view.bounds.width, height: 140 + kSafeBottomMargin)
        // layerFillCode
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor]
//        gradient.locations = [0,0.5,1]
        gradient.frame = layerView.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        layerView.layer.addSublayer(gradient)
        view.addSubview(layerView)
        let bundle = Bundle(for: MMCaptureViewController.self)
        let doneImage =  UIImage(named: "ic_big_done_step", in: bundle, compatibleWith: nil)
        self.confirmButton.setImage(doneImage, for: .normal)
        self.confirmButton.layer.cornerRadius = 20
        self.confirmButton.clipsToBounds = true
        self.confirmButton.backgroundColor = UIColor(red: 0.19, green: 0.82, blue: 0.55, alpha: 1)
        self.view.addSubview(self.confirmButton)
        let backImage =  UIImage(named: "ic_big_shoot_back", in: bundle, compatibleWith: nil)
        self.backButton.setImage(backImage, for: .normal)
        self.backButton.layer.cornerRadius = 20
        self.backButton.clipsToBounds = true
        self.view.addSubview(self.backButton)
        
        self.backButton.frame = CGRect.init(x: self.view.bounds.width / 2 - 20, y: self.view.bounds.height - 50 - kSafeBottomMargin - 40, width: 40, height: 40)
        
        blurView.frame = self.backButton.bounds
        blurView.layer.cornerRadius = 20
        blurView.layer.masksToBounds = true
        self.view.insertSubview(blurView, belowSubview: backButton)
        blurView.center = self.backButton.center
        self.confirmButton.frame = CGRect.init(x: self.view.bounds.width / 2 - 20, y: self.view.bounds.height - 50 - kSafeBottomMargin - 40, width: 40, height: 40)
        
        backTitle.font = UIFont.systemFont(ofSize: 12)
        backTitle.textColor = .white
        backTitle.text = "重拍"
        backTitle.textAlignment = .center
        self.view.addSubview(backTitle)
        backTitle.frame = CGRect.init(x: 50, y: confirmButton.frame.maxY + 8, width: 36, height: 12)
        confirmTitle.font = backTitle.font
        confirmTitle.textColor = backTitle.textColor
        confirmTitle.text = "完成"
        confirmTitle.textAlignment = .center
        self.view.addSubview(confirmTitle)
        confirmTitle.frame = CGRect.init(x: self.view.frame.width -  50 - 36, y: confirmButton.frame.maxY + 8, width: 36, height: 12)
        
        confirmTitle.alpha = 0
        backTitle.alpha = 0
        
    }    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        return .portrait
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension MMPreviewBaseViewController : UIViewControllerAnimatedTransitioning{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toVC  = transitionContext.viewController(forKey: .to) as! MMPreviewBaseViewController
        let containerView : UIView = transitionContext.containerView
        let toView : UIView = toVC.view
        containerView.addSubview(toView)
        self.confirmShowAnimation(transitionContext)
    }

    private func confirmShowAnimation(_ transitionContext : UIViewControllerContextTransitioning){

        UIView.setAnimationCurve(.easeInOut)
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: { [weak self] in
            guard let `self` = self else {return}
            self.backButton.frame = CGRect.init(x: 48, y: self.backButton.frame.origin.y, width: 40, height: 40)
            self.confirmButton.frame = CGRect.init(x: self.view.bounds.width - 48 - self.confirmButton.bounds.width, y: self.confirmButton.frame.origin.y, width: 40, height: 40)
            self.blurView.center = self.backButton.center
            self.confirmTitle.alpha = 1
            self.backTitle.alpha = 1
        }) { (finish) in
            transitionContext.completeTransition(true)
        }
    }

}
extension MMPreviewBaseViewController : UIViewControllerTransitioningDelegate{
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

