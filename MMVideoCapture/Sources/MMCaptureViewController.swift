//
//  MMCaptureViewController.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit
import Photos
@objc protocol MMCaptureViewControllerDelegate{
    func captureViewControllerDidDismiss(_ captureViewController: MMCaptureViewController)
    func captureViewController(_ captureViewController : MMCaptureViewController, didFinishPick image: UIImage,asset : PHAsset)
    func captureViewController(_ captureViewController : MMCaptureViewController, didFinishPickVideo url: URL, asset : PHAsset,coverImage : UIImage?)
}

class MMCaptureViewController: UIViewController {
    
    var maxVideoDuration : CGFloat = 20
    private var minVideoDuration : CGFloat = 1
    weak var delegate : MMCaptureViewControllerDelegate?
    private var videoDevice : AVCaptureDevice? = nil
    private var audioDevice : AVCaptureDevice? = nil
    private var videoInput : AVCaptureDeviceInput? = nil
    private var audioInput : AVCaptureDeviceInput? = nil
    private var imageOutput : AVCapturePhotoOutput? = nil
    private var movieOutput : AVCaptureMovieFileOutput? = nil
    private var session : AVCaptureSession? = nil
    private var previewLayer : AVCaptureVideoPreviewLayer? = nil
    private let switchButton : MMButton = MMButton(type: .custom)
    private let backButton : MMButton = MMButton(type: .custom)
    private let lightButton : MMButton = MMButton(type: .custom)
    private let progressView : MMVideoCaptureProgressView = MMVideoCaptureProgressView()
    private let snapButton : MMCaptureButton = MMCaptureButton()
    private let noticeLabel : UILabel = UILabel()
    private var setupComlete : Bool = false
    private var needStartSession : Bool = true
    private var countTimer : Timer? = nil
    private var currentTime : CGFloat = 0
    private var hasPriority : Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        MotionOrientation.shared.startAccelerometerUpdates()
        
        let action = {[weak self]() in
            self?.setupCamera { (completion) in
                if (completion){
                    self?.setupComlete = true
                    self?.perform(#selector(self?.hideTip), with: nil, afterDelay: 2)
                }
            }
        }
        if self.configAuthorization() {
            action()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: NSNotification.Name(rawValue: MotionConst.MotionOrientationChangedNotification), object: nil)
    }
    deinit {
        MotionOrientation.shared.stopAccelerometerUpdates()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkAndStart()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.hasPriority {
            self.stopSession()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func checkAndStart(){
        if self.hasPriority , self.setupComlete , self.needStartSession  {
            self.resetCapture()
            self.startSession()
        }
    }
    private func startRecord(){
        let filePath : String = NSUUID().uuidString

        self.countTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(calculateMaxDuration(_:)), userInfo: nil, repeats: true)
        let outputUrl : URL = URL(fileURLWithPath: NSTemporaryDirectory() + filePath + ".mov")
        self.movieOutput?.startRecording(to: outputUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
    }
    
    private func endRecord(){
        self.countTimer?.invalidate()
        self.countTimer = nil
        self.movieOutput?.stopRecording()
    }
    
    private func checkVideoDurationValid() -> Bool{
        return self.currentTime >= minVideoDuration
    }
    
    private func changeVideoZoomLevel(_ zoomFactor: CGFloat){
        guard let device = self.videoDevice else { return  }
        do {
           try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        } catch{
        }
    }
    
    private func changeVideoOrientation(_ orientation:UIInterfaceOrientation){
        if let output = self.movieOutput, let connection = self.movieOutput?.connection(with: .video), !output.isRecording,connection.isVideoOrientationSupported{
            connection.videoOrientation = transformOrientation(orientation: orientation)
            rotateButtonForOrientation(orientation)
        }
        if  let connection = self.imageOutput?.connection(with: .video),connection.isVideoOrientationSupported{
            connection.videoOrientation = transformOrientation(orientation: orientation)
        }
    }
    
    private func rotateButtonForOrientation(_ orientation:UIInterfaceOrientation){
        var angle : Float = 0
        switch orientation {
        case .landscapeLeft:
            angle = -Float.pi / 2
        case .landscapeRight:
            angle = Float.pi / 2
        case .portraitUpsideDown:
            angle = Float.pi
        default:
            break
        }
        let transform = CGAffineTransform.init(rotationAngle: CGFloat(angle))
        UIView.animate(withDuration: 0.25) {
            self.backButton.transform = transform
            self.lightButton.transform = transform
            self.switchButton.transform = transform
        }
    }
    
    private func resetCapture(){
        guard let device = self.videoDevice else { return  }
        do {
           try device.lockForConfiguration()
            device.videoZoomFactor = 1
            device.unlockForConfiguration()
        } catch{
        }
        self.currentTime = 0
        self.lightButton.isSelected = false
        self.progressView.value = 0
    }
    
    private func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    @objc private func deviceOrientationDidChange(_ noti:Notification){
        DispatchQueue.main.async {
            guard  let dic = noti.userInfo as? [String : Any], let motionOritentation = dic[MotionConst.kMotionOrientationKey] as? MotionOrientation else {
                return
            }
            let orientation = motionOritentation.interfaceOrientation
//            print("orientation changed: \(orientation.rawValue)")
            self.changeVideoOrientation(orientation)
        }
    }
    
    @objc private func calculateMaxDuration(_ t : Timer){
        self.currentTime = self.currentTime + CGFloat(t.timeInterval)
        if self.currentTime > self.maxVideoDuration{
            self.progressView.value = 1
            self.endRecord()
        }
        else{
            print("")
            self.progressView.value = CGFloat(self.currentTime) / self.maxVideoDuration
        }
    }
    
    @objc private func switchCameraPosition(_ : UIButton){
        if self.videoDevice?.position == .back {
            if self.isFrontCameraAvailable(){
                self.session?.beginConfiguration()
                self.session?.removeInput(self.videoInput!)
//                let devices = DiscoverySession.devices
                for device in AVCaptureDevice.devices(for: .video){
                    if device.position == .front{
                        self.lightButton.isEnabled = false
                        self.videoDevice = device
                        break;
                    }
                }
                self.videoInput = try? AVCaptureDeviceInput(device: self.videoDevice!)
                
                if (self.session?.canAddInput(self.videoInput!))!{
                    self.session?.addInput(self.videoInput!)
                }
                
                self.session?.commitConfiguration()
            }
        }
        else{
            if self.isRearCameraAvailable(){
                self.session?.beginConfiguration()
                self.session?.removeInput(self.videoInput!)
                
                for device in AVCaptureDevice.devices(for: .video){
                    if device.position == .back{
                        self.lightButton.isEnabled = true
                        self.videoDevice = device
                        break;
                    }
                }
                self.videoInput = try? AVCaptureDeviceInput(device: self.videoDevice!)
                
                if (self.session?.canAddInput(self.videoInput!))!{
                    self.session?.addInput(self.videoInput!)
                }
                
                self.session?.commitConfiguration()
            }
        }
    }
    
    @objc private func backButton_pressed(_ sender : UIButton){
        self.dismiss(animated: true) {[weak self] in
            self?.delegate?.captureViewControllerDidDismiss(self!)
        }
    }
    
    @objc private func lightButton_pressed(_ sender:UIButton){
        
        guard let device = self.videoDevice, let configSession = self.session else { return  }
        sender.isSelected = !sender.isSelected
        let targetMode : AVCaptureDevice.TorchMode = sender.isSelected ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
        let flashMode : AVCaptureDevice.FlashMode = sender.isSelected ? AVCaptureDevice.FlashMode.on : AVCaptureDevice.FlashMode.off
        if device.hasTorch && device.hasFlash {
            if device.torchMode != targetMode {
                do{
                    try device.lockForConfiguration()
                    configSession.beginConfiguration()
                    device.torchMode = targetMode
                    device.flashMode = flashMode
                    configSession.commitConfiguration()
                    device.unlockForConfiguration()
                }catch{
                }
                
            }
        }
    }
    
    @objc private func hideTip(){
        self.noticeLabel.isHidden = true
    }
    
    private func loadUI(){
        self.view.backgroundColor = UIColor.black
        let bundle = Bundle(for: MMCaptureViewController.self)
        let kSafeBottomMargin = MMsafeAreaInsets().bottom

        let topMask = MMCaptureMaskView.init(with: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: kStatusBarHeight + 44), startPoint: CGPoint.init(x: 0, y: 1), endPoint: CGPoint.init(x: 0, y: 0))
        view.addSubview(topMask)
        
        let bottomMask = MMCaptureMaskView(frame: CGRect(x: 0, y: view.bounds.height - 140 - kSafeBottomMargin, width: self.view.bounds.width, height: 140 + kSafeBottomMargin))
        view.addSubview(bottomMask)
        self.view.addSubview(progressView)
        progressView.isHidden = true
        let closeImage =  UIImage(named: "ic_big_nav_closepage_white", in: bundle, compatibleWith: nil)
        self.backButton.setImage(closeImage, for: .normal)
        self.backButton.addTarget(self, action: #selector(backButton_pressed(_:)), for: .touchUpInside)
        self.view.addSubview(self.backButton)
        let flipImage =  UIImage(named: "ic_big_shoot_flip_camera", in: bundle, compatibleWith: nil)
        self.switchButton.setImage(flipImage, for: .normal)
        self.switchButton.addTarget(self, action: #selector(switchCameraPosition(_:)), for: .touchUpInside)
        self.view.addSubview(self.switchButton)
        var tip = "轻触拍照，按住摄像"
        if let nav = self.navigationController as? MMCameraViewController{
            if nav.allowedCaptureType == .photo{
                tip = "轻触拍照"
                progressView.isHidden = true
            }else if nav.allowedCaptureType == .video{
                tip = "按住摄像"
            }
        }
        self.noticeLabel.font = UIFont.systemFont(ofSize: 12)
        self.noticeLabel.text = tip
        self.noticeLabel.textColor = UIColor.white
        self.view.addSubview(self.noticeLabel)
        
        self.snapButton.delegate = self
        self.view.addSubview(self.snapButton)
        let spark = UIImage(named: "ic_big_shoot_spark", in: bundle, compatibleWith: nil)
        let noSpark = UIImage(named: "ic_big_shoot_no_spark", in: bundle, compatibleWith: nil)
        self.lightButton.setImage(noSpark, for: .normal)
        self.lightButton.setImage(spark, for: .selected)
        self.lightButton.addTarget(self, action: #selector(lightButton_pressed(_:)), for: .touchUpInside)
        self.view.addSubview(self.lightButton)
        let topMargin : CGFloat = MMsafeAreaInsets().top

        self.backButton.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.top.equalTo(8 + topMargin)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        self.switchButton.snp.makeConstraints { (make) in
            make.size.equalTo(self.backButton.snp.size)
            make.centerY.equalTo(self.backButton.snp.centerY)
            make.trailing.equalTo(-16)
        }
        
        self.lightButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.switchButton.snp.centerY)
            make.size.equalTo(self.switchButton.snp.size)
            make.trailing.equalTo(self.switchButton.snp.leading).offset(-16)
        }
        
        self.noticeLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.snapButton.snp.top).offset(-12)
            make.width.lessThanOrEqualTo(200)
            make.height.equalTo(14)
            make.centerX.equalTo(self.view)
        }
        
        self.snapButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-32 - kSafeBottomMargin)
            make.width.equalTo(76)
            make.height.equalTo(76)
        }
        let pinch = UIPinchGestureRecognizer.init(target: self, action: #selector(handlePinch(_:)))
        self.view.addGestureRecognizer(pinch)
        
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
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc private func handlePinch(_ ges : UIPinchGestureRecognizer){
        print("pinch scale is\(ges.scale)")
        switch ges.state {
        case .began:
            print("state is \(ges.state.rawValue)")
        case .changed:
            print("state is \(ges.state.rawValue)")
            guard let device = self.videoDevice else { return  }
            let format = device.activeFormat
            let maxZoom = min( format.videoMaxZoomFactor, 6)
            let pre = device.videoZoomFactor
            let mul : CGFloat = ges.scale > 1 ? 1 : -1
            let current = mul *  0.08 + pre
            if (current == pre || current > maxZoom || current < 1){
                return
            }
            self.changeVideoZoomLevel(current)
        case .ended:
            print("state is \(ges.state.rawValue)")
        default:
            print("state is \(ges.state.rawValue)")
        }
    }

}

extension MMCaptureViewController : MMPhotoPreviewViewControllerDelegate{
    func photoPreviewViewController(_ previewViewController: MMPhotoPreviewViewController, didFinishPick image: UIImage, asset: PHAsset) {
        self.needStartSession = false
        self.delegate?.captureViewController(self, didFinishPick: image, asset: asset)
        self.dismiss(animated: true) {[weak self] in
            self?.delegate?.captureViewControllerDidDismiss(self!)
        }
    }
}

extension MMCaptureViewController : MMVideoPreviewViewControllerDelegate{
    func videoPreviewViewController(_ videoPreviewController: MMVideoPreviewViewController, didFinishPick videoUrl: URL, videoAsset: PHAsset, coverImage: UIImage?) {
        self.needStartSession = false
        self.delegate?.captureViewController(self, didFinishPickVideo: videoUrl,asset: videoAsset,coverImage: coverImage)
        self.dismiss(animated: true) {[weak self] in
            self?.delegate?.captureViewControllerDidDismiss(self!)
        }
    }
}

extension MMCaptureViewController : AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if !self.checkVideoDurationValid() {
            print("拍摄时间过短")  //
            self.captureButtonPressed(button: self.snapButton)
            return
        }
        let previewVC = MMVideoPreviewViewController()
        previewVC.playerUrl = outputFileURL
        previewVC.delegate = self
        self.navigationController?.pushViewController(previewVC, animated: true)
    }
}

extension MMCaptureViewController : AVCapturePhotoCaptureDelegate{
    // ios 11+
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        guard let data = imageData else { return  }
        let image = UIImage(data: data)
        previewImage(image)
    }
    // ios 10
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard let buffer = photoSampleBuffer, let preBuffer = previewPhotoSampleBuffer else { return  }
        let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: preBuffer)
        guard let data = imageData else { return  }
        let image = UIImage(data: data)
        previewImage(image)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if let nav = self.navigationController as? MMCameraViewController,nav.disableShotSound == true{
               //屏蔽拍照的声音
               AudioServicesDisposeSystemSoundID(1108)
        }
    }
    private func previewImage(_ image:UIImage?){
        guard let _ = image else { return  }
        let previewVC = MMPhotoPreviewViewController()
        previewVC.image = image
        previewVC.delegate = self
        self.navigationController?.pushViewController(previewVC, animated: true)
    }
    
}

extension MMCaptureViewController : MMCaptureButtonDelegate{
    func captureButtonPressed(button: MMCaptureButton) {
        if let nav = self.navigationController as? MMCameraViewController,nav.allowedCaptureType == .video{
            return // 如果只允许 拍视频。
        }
        let connection = self.imageOutput?.connection(with: .video)
        if connection  == nil{
            print("拍照失败")
            return
        }
        let setting = AVCapturePhotoSettings.init()
        setting.flashMode = self.lightButton.isSelected ? AVCaptureDevice.FlashMode.on : AVCaptureDevice.FlashMode.off
        self.imageOutput?.capturePhoto(with: setting, delegate: self)
    }
    
    func captureButtonLongPressed(button: MMCaptureButton, began: Bool) {
        if let nav = self.navigationController as? MMCameraViewController,nav.allowedCaptureType == .photo{
            return // 如果只允许拍照片。
        }
            if began {
                self.progressView.isHidden = false
                self.backButton.isHidden = true
                self.lightButton.isHidden = true
                self.switchButton.isHidden = true
                UIView.setAnimationCurve(.easeInOut)
                UIView.animate(withDuration: 0.1, animations: { [weak self] in
                    self?.snapButton.snp.updateConstraints { (make) in
                        make.width.equalTo(86)
                        make.height.equalTo(86)
                    }
                    self?.view.layoutIfNeeded()
                }) {[weak self] (finish) in
                    self?.progressView.isHidden = false
                    self?.progressView.frame = (self?.snapButton.frame)!
                }
                self.startRecord()
            }
            else{
                self.progressView.isHidden = true
                self.backButton.isHidden = false
                self.lightButton.isHidden = false
                self.switchButton.isHidden = false
                self.endRecord()
                UIView.setAnimationCurve(.easeInOut)
                               UIView.animate(withDuration: 0.1, animations: { [weak self] in
                                   self?.snapButton.snp.updateConstraints { (make) in
                                       make.width.equalTo(76)
                                       make.height.equalTo(76)
                                   }
                                   self?.view.layoutIfNeeded()
                               }) { (finish) in
                                self.progressView.isHidden = true
                               }
            }
        }
    
    func captureButtonLongPressed(button: MMCaptureButton, zoomingLevel: CGFloat) {
        guard let device = self.videoDevice else { return  }
        let format = device.activeFormat
        let maxZoom = min( format.videoMaxZoomFactor, 6)
        let pre = device.videoZoomFactor
        let current = (maxZoom - 1) * zoomingLevel + 1
        if (current == pre){
            return
        }
        self.changeVideoZoomLevel(current)
    }
}

// MARK: - 相机配置
extension MMCaptureViewController{
    private func isRearCameraAvailable() -> Bool{
        return UIImagePickerController.isCameraDeviceAvailable(.rear)
    }
    
    private func isFrontCameraAvailable() -> Bool{
        return UIImagePickerController.isCameraDeviceAvailable(.front)
    }
    
    private func setupCamera(completion: @escaping (_  : Bool) -> Void){
        DispatchQueue.global(qos: .default).async { [weak self] in
            self?.videoDevice = AVCaptureDevice.default(for: .video)
            self?.audioDevice = AVCaptureDevice.default(for: .audio)
            
            self?.videoInput = try? AVCaptureDeviceInput.init(device: (self?.videoDevice!)!)
            self?.audioInput = try? AVCaptureDeviceInput.init(device: (self?.audioDevice!)!)
            
            self?.imageOutput = AVCapturePhotoOutput()
            self?.movieOutput = AVCaptureMovieFileOutput()
            
            self?.session = AVCaptureSession()
            self?.session?.canSetSessionPreset(.high)
            
            if (self?.session?.canAddInput((self?.videoInput!)!))!{
                self?.session?.addInput((self?.videoInput!)!)
            }
            
            if (self?.session?.canAddInput((self?.audioInput!)!))!{
                self?.session?.addInput((self?.audioInput!)!)
            }
            
            if (self?.session?.canAddOutput((self?.imageOutput!)!))!{
                self?.session?.addOutput((self?.imageOutput!)!)
            }
            
            if (self?.session?.canAddOutput((self?.movieOutput!)!))!{
                self?.session?.addOutput((self?.movieOutput!)!)
                
                let connection = self?.movieOutput?.connection(with: .video)
                if (connection?.isVideoStabilizationSupported)!{
                    connection?.preferredVideoStabilizationMode = .cinematic
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.previewLayer = AVCaptureVideoPreviewLayer(session: (self?.session!)!)
                self?.previewLayer?.videoGravity = .resizeAspectFill
                
                self?.previewLayer?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
                self?.view.layer.addSublayer((self?.previewLayer!)!)
                
                self?.loadUI()
                completion(true)
            }
        }
    }
}

// MARK: - Method
extension MMCaptureViewController{
    private func startSession(){
        if !(self.session?.isRunning)! {
            self.session?.startRunning()
        }
    }
    
    private func stopSession(){
        if (self.session?.isRunning)! {
            self.session?.stopRunning()
        }
    }
    
    private func configAuthorization() -> Bool{
        let authStatus : AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .denied || authStatus == .restricted {
            let alert = UIAlertController.init(title: "没有相机权限", message: "请去设置-隐私-相机中对应用授权", preferredStyle: .alert)
            let settingUrl = URL.init(string: UIApplication.openSettingsURLString)!
            alert.addAction(UIAlertAction.init(title: "好的", style: .default, handler: { (_) in
                if(UIApplication.shared.canOpenURL(settingUrl)){
                    UIApplication.shared.open(settingUrl, options: [:], completionHandler: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
            self.hasPriority = false;
            return false
        }
        self.hasPriority = true;
        return true
    }
}
