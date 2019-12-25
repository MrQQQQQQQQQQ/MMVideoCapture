//
//  AppDelegate.swift
//  MMVideoCaptureDemo
//
//  Created by minsir on 2019/12/20.
//  Copyright © 2019 aimymusic. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window : UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow.init(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        return true
    }

   


}

