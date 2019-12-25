//
//  MMVideoCaptureCons.swift
//  MMVideoCapture
//
//  Created by minsir on 2019/10/25.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit

func MMIsIPhoneXType() -> Bool {
    guard #available(iOS 11.0, *) else {
        return false
    }
    return UIApplication.shared.windows.first?.safeAreaInsets.bottom != 0
}

func MMsafeAreaInsets() ->UIEdgeInsets{
    guard #available(iOS 11.0, *) else {
        return UIEdgeInsets.zero
    }
    return UIApplication.shared.keyWindow!.safeAreaInsets
}

let kStatusBarHeight: CGFloat = MMIsIPhoneXType() ? 44.0 : 20.0


func MMimageByApplyingAlpha(_ alpha: CGFloat,_ image:UIImage) -> UIImage{
    UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
    guard let ctx = UIGraphicsGetCurrentContext() , let cgImage = image.cgImage else {return image}
    let area = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    ctx.scaleBy(x: 1, y: -1)
    ctx.translateBy(x: 0, y: -area.size.height)
    ctx.setBlendMode(.multiply)
    ctx.setAlpha(alpha)
    ctx.draw(cgImage, in: area)
    let newImage =  UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage ?? image
}

