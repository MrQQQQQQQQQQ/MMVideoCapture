# MMVideoCapture
类似微信的拍照/摄像组件，短按拍照片，长按则进行视频拍摄。有对应的照片和视频的预览页面。
# ScreenShot
<img width="375" height="667" src="https://github.com/MrQQQQQQQQQQ/MMVideoCapture/raw/master/MMVideoCaptureDemo/ScreenShots/IMG_2097.PNG"/>
<img width="375" height="667" src="https://github.com/MrQQQQQQQQQQ/MMVideoCapture/raw/master/MMVideoCaptureDemo/ScreenShots/IMG_2098.PNG"/>

# Installation
    pod "MMVideoCapture"
# Usage
## 1st.
     let vc = MMCameraViewController.init(delegate: self)
     self.present(vc, animated: true, completion: nil)
## 2nd.
    extension ViewController : MMCameraViewControllerDelegate{
        func cameraViewController(_ cameraViewController: MMCameraViewController, didFinishPick image: UIImage, asset: PHAsset) {
        
        }
    
        func cameraViewController(_ cameraViewController: MMCameraViewController, didFinishPickVideo url: URL, asset: PHAsset, coverImage: UIImage?) {
        
        }
    
        func cameraViewControllerDidDismiss(_ cameraViewController: MMCameraViewController) {
        
        }
    }
