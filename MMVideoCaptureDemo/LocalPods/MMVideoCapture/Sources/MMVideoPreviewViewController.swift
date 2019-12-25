//
//  MMVideoPreviewViewController.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit
import AVKit
import Photos
@objc protocol MMVideoPreviewViewControllerDelegate{
    func videoPreviewViewController(_ videoPreviewController: MMVideoPreviewViewController, didFinishPick videoUrl : URL, videoAsset : PHAsset,coverImage:UIImage?)
}

class MMVideoPreviewViewController: MMPreviewBaseViewController {
    var playerUrl : URL? = nil
    weak var delegate : MMVideoPreviewViewControllerDelegate? = nil
    private var isSaving  = false
    private var playerLayer : AVPlayerLayer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        installNotificationObserver()
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func confirmButton_pressed(_ : UIButton){
        
        guard let path = self.playerUrl, self.isSaving == false  else { return  }
        self.isSaving = true
        var localidentifier : String?
        PHPhotoLibrary.shared().performChanges({
            let request =  PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: path)
            localidentifier = request!.placeholderForCreatedAsset?.localIdentifier
        }) { saved, error in
            if saved && localidentifier != nil {
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localidentifier!], options: nil).firstObject else {return}
                let photoWidth = UIScreen.main.bounds.width
                let aspectRatio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
                var pixelWidth = photoWidth * UIScreen.main.scale * 1.5
                //超宽图片
                if aspectRatio > 1.8 {
                    pixelWidth = pixelWidth * aspectRatio
                }
                //超高图片
                if aspectRatio < 0.2 {
                    pixelWidth = pixelWidth * 0.5
                }
                let pixelHeight = pixelWidth / aspectRatio
                let imageSize = CGSize.init(width: pixelWidth, height: pixelHeight)
                let option = PHImageRequestOptions.init()
                option.resizeMode = PHImageRequestOptionsResizeMode.fast
                option.isNetworkAccessAllowed = true
                PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: PHImageContentMode.aspectFill, options: option) { (image, info) in
                    
                    var isCancel = false
                    var hasError = false
                    var isDegraded = true
                    if let dict = info {
                        //是否取消
                        if let cancel = dict[PHImageCancelledKey] as? Bool {
                            isCancel = cancel
                        }
                        //是否出错
                        if let _ = dict[PHImageErrorKey] {
                            hasError = true
                        }
                        //当前图片是否是低质量的
                        if let degraded = dict[PHImageResultIsDegradedKey] as? Bool {
                            isDegraded = degraded
                        }else{
                            isDegraded = false
                        }
                        // 这个方法会回调多次，返回低质量图片时 不处理
                        if isDegraded || hasError || isCancel {
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        self.delegate?.videoPreviewViewController(self, didFinishPick: self.playerUrl!,videoAsset: asset,coverImage: image)
                        self.navigationController?.popViewController(animated: false)
                    }
                    
                }
            }
        }
    }
    
    @objc private func backButton_pressed(_ : Any){
        self.playerLayer?.player?.pause()
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc private func save(_ video:String,didFinishSavingWith error:Error){
        print("video at :\(video) save finished with error : \(error)")
    }
    
    private func installNotificationObserver(){
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self](_) in
             DispatchQueue.main.async {
                self?.playerLayer?.player?.seek(to: CMTime.zero)
                 self?.playerLayer?.player?.play()
             }
             
         }
        
    }
    
    internal override func loadUI(){
        let playerItem : AVPlayerItem = AVPlayerItem(url: self.playerUrl!)
        let player : AVPlayer = AVPlayer(playerItem: playerItem)
        self.playerLayer = AVPlayerLayer.init(player: player)
        self.playerLayer?.frame = self.view.bounds
        self.view.layer.addSublayer(self.playerLayer!)
        self.playerLayer?.player?.play()
        super.loadUI()
        self.backButton.addTarget(self, action: #selector(backButton_pressed(_:)), for: .touchUpInside)
        self.confirmButton.addTarget(self, action: #selector(confirmButton_pressed(_:)), for: .touchUpInside)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

