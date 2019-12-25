//
//  MMPhotoPreviewViewController.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit
import Photos
@objc protocol MMPhotoPreviewViewControllerDelegate{
    func photoPreviewViewController(_ previewViewController: MMPhotoPreviewViewController, didFinishPick image: UIImage,asset:PHAsset)
}

class MMPhotoPreviewViewController: MMPreviewBaseViewController {
    var image : UIImage? = nil
    weak var delegate : MMPhotoPreviewViewControllerDelegate? = nil
    private var isSaving = false
    private let imageView : UIImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func confirmButton_pressed(_ : UIButton){
        
        guard let img = self.image , self.isSaving == false else { return  }
        
        var localidentifier : String?
        self.isSaving = true
        PHPhotoLibrary.shared().performChanges({
            let request =  PHAssetChangeRequest.creationRequestForAsset(from: img)
            localidentifier = request.placeholderForCreatedAsset?.localIdentifier
        }) {saved, error in
            if saved && localidentifier != nil {
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localidentifier!], options: nil).firstObject else {return}
                DispatchQueue.main.async {
                    self.delegate?.photoPreviewViewController(self, didFinishPick: img, asset: asset)
                    self.navigationController?.popViewController(animated: false)
                }
            }
        }
    }
    
    @objc private func backButton_pressed(_ : Any){
        self.navigationController?.popViewController(animated: false)
    }
    
    internal override func loadUI(){
        self.imageView.image = self.image
        self.view.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        super.loadUI()
        self.backButton.addTarget(self, action: #selector(backButton_pressed(_:)), for: .touchUpInside)
        self.confirmButton.addTarget(self, action: #selector(confirmButton_pressed(_:)), for: .touchUpInside)
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }

}

