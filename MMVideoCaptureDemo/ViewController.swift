//
//  ViewController.swift
//  MMVideoCaptureDemo
//
//  Created by minsir on 2019/12/20.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit
import MMVideoCapture
import Photos
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let btn = UIButton.init(type: .custom)
        view.addSubview(btn)
        btn.setTitle("拍照", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.sizeToFit()
        view.addSubview(btn)
        btn.center = CGPoint.init(x: view.frame.size.width / 2, y: view.frame.size.height / 2)
        btn.addTarget(self, action: #selector(handleBtnClicked), for: .touchUpInside)
    }

    
    @objc private func handleBtnClicked(){

        let vc = MMCameraViewController.init(delegate: self)
        self.present(vc, animated: true, completion: nil)
    }

}

extension ViewController : MMCameraViewControllerDelegate{
    func cameraViewController(_ cameraViewController: MMCameraViewController, didFinishPick image: UIImage, asset: PHAsset) {
        
    }
    
    func cameraViewController(_ cameraViewController: MMCameraViewController, didFinishPickVideo url: URL, asset: PHAsset, coverImage: UIImage?) {
        
    }
    
    func cameraViewControllerDidDismiss(_ cameraViewController: MMCameraViewController) {
        
    }
    
}

