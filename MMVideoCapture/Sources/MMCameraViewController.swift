//
//  MMCameraViewController.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit
import Photos

public protocol MMCameraViewControllerDelegate : NSObjectProtocol{
    func cameraViewControllerDidDismiss(_ cameraViewController: MMCameraViewController)
    func cameraViewController(_ cameraViewController: MMCameraViewController, didFinishPick image : UIImage,asset : PHAsset)
    func cameraViewController(_ cameraViewController: MMCameraViewController, didFinishPickVideo url : URL,asset: PHAsset, coverImage: UIImage?)
}
public enum MMCaptureType : Int {
    case none = 0x0
    case photo =  0x1
    case video = 0x10
    case all = 0x11
}
open class MMCameraViewController: UINavigationController {
    open weak var cameraDelegate : MMCameraViewControllerDelegate? = nil
    public var allowedCaptureType : MMCaptureType = .all
    public var disableShotSound : Bool = false // 关闭快门声
   public convenience init(delegate : MMCameraViewControllerDelegate?) {
        let rootVC = MMCaptureViewController()
        self.init(rootViewController: rootVC)
//        self.modalPresentationStyle = .fullScreen;
        self.cameraDelegate = delegate
        rootVC.delegate = self
    }
    deinit {
        print("MMCameraViewController deinit")
    }
    private func checkAuthorized(_ authorization :@escaping (_ authorized: Bool) -> (Void)){

        let checkMic = {() in
            AVCaptureDevice.requestAccess(for: .audio) { (suc) in
                if (suc){
                    authorization(true)
                }else{
                    authorization(false)
                }
            }
        }
        let checkCamera = {() in
            AVCaptureDevice.requestAccess(for: .video) { (suc) in
                 if suc {
                    checkMic()
                 } else {
                    authorization(false)
                 }
             }
        }
        // check albumAuth
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                DispatchQueue.main.async {
                    checkCamera()
                }
            } else {
                authorization(false)
            }
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.isHidden = true
        self.delegate = self
        // Do any additional setup after loading the view.
        
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    private func  normalizedImage(_ image:UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return  image
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: image.size))
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}

extension MMCameraViewController : MMCaptureViewControllerDelegate{
    func captureViewControllerDidDismiss(_ captureViewController: MMCaptureViewController) {
        self.cameraDelegate?.cameraViewControllerDidDismiss(self)
    }
    
    func captureViewController(_ captureViewController: MMCaptureViewController, didFinishPick image: UIImage, asset: PHAsset) {
        self.cameraDelegate?.cameraViewController(self, didFinishPick: self.normalizedImage(image),asset:asset)
    }
    
    func captureViewController(_ captureViewController: MMCaptureViewController, didFinishPickVideo url: URL, asset: PHAsset, coverImage: UIImage?) {
        let normalizedimg = self.normalizedImage(coverImage ?? UIImage())
        self.cameraDelegate?.cameraViewController(self, didFinishPickVideo: url, asset: asset, coverImage: normalizedimg)
    }
}

extension MMCameraViewController : UINavigationControllerDelegate{
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
            case .none:
                return nil
            case .push:
                return toVC as? UIViewControllerAnimatedTransitioning
            case .pop:
                return fromVC as? UIViewControllerAnimatedTransitioning
        }
    }
    
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
