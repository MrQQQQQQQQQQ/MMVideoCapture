Pod::Spec.new do |s|

  s.name         = "MMVideoCapture"
  s.version      = "0.0.1"
  s.summary      = "类似微信的拍照/摄像组件，短按拍照片，长按则进行视频拍摄。有对应的照片和视频的预览页面。"

  s.homepage     = "https://github.com/MrQQQQQQQQQQ/MMVideoCapture"

  s.license= { :type => "MIT", :file => "LICENSE" }

  s.author             = { "minsir" => "minsir.iosdev@gmail.com" }

  s.platform     = :ios, "10.0"
  s.swift_versions =  '4.2'


  s.source       = { :git => "https://github.com/MrQQQQQQQQQQ/MMVideoCapture.git", :tag => "0.0.1" }

  s.source_files  = "MMVideoCapture/Sources/*"

  s.framework    = "UIKit","Foundation","Photos","AVFoundation","AVKit"

  s.resources = "MMVideoCapture/buildinIcons/*.png"

  s.dependency "SnapKit", "~> 4.0.0"

  s.requires_arc = true


end