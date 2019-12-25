
Pod::Spec.new do |spec|

  spec.name         = "MMVideoCapture"
  spec.version      = "0.0.1"
  spec.summary      = "A swift Video capture kit"
  spec.description  = <<-DESC
A swift Video capture kit
                   DESC

  spec.homepage     = "https://github.com/MrQQQQQQQQQQ/MMVideoCapture"

  spec.license      = "MIT"

  spec.author             = { "minsir" => "minsir.min@aimymusic.com" }

  spec.platform     = :ios, "10.0"


  spec.source       = { :git => "https://github.com/MrQQQQQQQQQQ/MMVideoCapture.git", :tag => "#{spec.version}" }



  spec.source_files  = "Sources/*.swift", "Sources/*.h"
  spec.exclude_files = "Classes/Exclude"

  # spec.public_header_files = "Classes/**/*.h"

  spec.framework    = "UIKit","Foundation","Photos","AVFoundation","AVKit"

  spec.resources = "buildinIcons/*.png"

  spec.dependency "SnapKit", "~> 4.0.0"

end
