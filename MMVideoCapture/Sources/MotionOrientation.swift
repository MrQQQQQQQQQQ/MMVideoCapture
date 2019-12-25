//
//  MotionOrientation.swift
//
//  Created by minsir on 2019/10/24.
//

import UIKit
import CoreMotion
import CoreGraphics
func MO_degreesToRadian(_ x : Float) -> Float {
    return Float.pi * x / 180.0
}

struct MotionConst {
    static let MotionOrientationChangedNotification = "MotionOrientationChangedNotification"
    static let MotionOrientationInterfaceOrientationChangedNotification = "MotionOrientationInterfaceOrientationChangedNotification"
    static let MotionOrientationAccelerometerUpdatedNotification = "MotionOrientationAccelerometerUpdatedNotification"
    static let kMotionOrientationKey = "kMotionOrientationKey"
    static let kMotionOrientationDebugDataKey = "kMotionOrientationDebugDataKey"
}

class MotionOrientation: NSObject {

    static let shared = MotionOrientation()
    
    private(set) var interfaceOrientation : UIInterfaceOrientation = .unknown
    private(set) var deviceOrientation : UIDeviceOrientation = .unknown
    var affineTransform : CGAffineTransform {
        get{
            var rotationDegree : Float = 0
            switch interfaceOrientation {
            case .portrait:
                rotationDegree = 0
            case .landscapeLeft:
                rotationDegree = 90
            case .portraitUpsideDown:
                rotationDegree = 180
            case .landscapeRight:
                rotationDegree = 270
            default: break
            }
            return CGAffineTransform.init(rotationAngle: CGFloat(MO_degreesToRadian(rotationDegree)))
        }
    }
    private var motionManager : CMMotionManager = CMMotionManager()
    private var operationQueue : OperationQueue = OperationQueue()
    
    override init() {
        super.init()
        _initialize()
    }
    private func _initialize(){
        motionManager.accelerometerUpdateInterval = 0.1
        if !motionManager.isAccelerometerAvailable {
            print("MotionOrientation - Accelerometer is NOT available")
        }
    }
    
    private func accelerometerUpdateWithData(_ data:CMAccelerometerData?, error: Error?){
        if error != nil {
            print("accelerometerUpdateERROR:\(String(describing: error))")
        }
        guard let acceleration = data?.acceleration else {return}
        let xx = -acceleration.x
        let yy = acceleration.y
        let z = acceleration.z
        let angle = atan2(yy, xx)
        // Add 1.5 to the angle to keep the label constantly horizontal to the viewer.
        //    [interfaceOrientationLabel setTransform:CGAffineTransformMakeRotation(angle+1.5)];

        // Read my blog for more details on the angles. It should be obvious that you
        // could fire a custom shouldAutorotateToInterfaceOrientation-event here.

        let newInterfaceOrientation = interfaceOrientationWithCurrentInterfaceOrientation(self.interfaceOrientation, angle: angle, z: z)
//        print("newInterfaceOrientation is \(newInterfaceOrientation.rawValue)")
        let newDeviceOrientation = deviceOrientationWithCurrentDeviceOrientation(self.deviceOrientation, angle: angle, z: z)
        
        var deviceOrientationChanged = false
        var interfaceOrientationChanged = false

        if ( newDeviceOrientation != self.deviceOrientation ) {
            deviceOrientationChanged = true
            self.deviceOrientation = newDeviceOrientation;
        }

        if ( newInterfaceOrientation != self.interfaceOrientation ) {
            interfaceOrientationChanged = true
            self.interfaceOrientation = newInterfaceOrientation
        }

        // post notifications
        if ( deviceOrientationChanged ) {
            let debug = debugDataStringWithZ(z, withAngle: angle)
            let userInfo = [
                MotionConst.kMotionOrientationKey : self,
                MotionConst.kMotionOrientationDebugDataKey : debug
                ] as [String : Any]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MotionConst.MotionOrientationChangedNotification), object: nil, userInfo: userInfo)
    }

    if ( interfaceOrientationChanged ) {
        let debug = debugDataStringWithZ(z, withAngle: angle)
        let userInfo = [
            MotionConst.kMotionOrientationKey : self,
            MotionConst.kMotionOrientationDebugDataKey : debug
            ] as [String : Any]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MotionConst.MotionOrientationInterfaceOrientationChangedNotification), object: nil, userInfo: userInfo)
    }
}
    
    private func debugDataStringWithZ(_ z:Double , withAngle angle :Double)-> String{
//        return [NSString stringWithFormat:@"<z: %.3f> <angle: %.3f>", z, angle];
        return "<z:\(z)> <angle:\(angle)>"
    }
    
    private func interfaceOrientationWithCurrentInterfaceOrientation(_ interfaceOrientation:UIInterfaceOrientation, angle:Double,z:Double) -> UIInterfaceOrientation{
        switch deviceOrientationWithCurrentDeviceOrientation(deviceOrientationForInterfaceOrientation(interfaceOrientation), angle: angle, z: z) {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return interfaceOrientation
        }
    }
    
    
    private func deviceOrientationForInterfaceOrientation(_ interfaceOrientation:UIInterfaceOrientation) -> UIDeviceOrientation{
        switch interfaceOrientation {
            // UIDeviceOrientation and UIInterfaceOrientation : left and right are reversed
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    private func deviceOrientationWithCurrentDeviceOrientation(_ currentOrientation:UIDeviceOrientation, angle:Double, z :Double) ->UIDeviceOrientation{
        
        let absoluteZ  = fabs(z)
        var deviceOrientation = currentOrientation
        if (deviceOrientation == .faceUp || deviceOrientation == .faceDown) {
            if (absoluteZ < 0.845) {
                if (angle < -2.6) {
                    deviceOrientation = .landscapeRight
                } else if (angle > -2.05 && angle < -1.1) {
                    deviceOrientation = .portrait
                } else if (angle > -0.48 && angle < 0.48) {
                    deviceOrientation = .landscapeLeft
                } else if (angle > 1.08 && angle < 2.08) {
                    deviceOrientation = .portraitUpsideDown
                }
            } else if (z < 0.0) {
                deviceOrientation = .faceUp
            } else if (z > 0.0) {
                deviceOrientation = .faceDown
            }
        } else {
            if (z > 0.875) {
                deviceOrientation = .faceDown
            } else if (z < -0.875) {
                deviceOrientation = .faceUp
            } else {
                switch (deviceOrientation) {
                case .landscapeLeft:
                    if (angle < -1.07){
                        return .portrait
                    }
                    if (angle > 1.08){
                        return .portraitUpsideDown
                    }
                    break;
                case .landscapeRight:
                    if (angle < 0.0 && angle > -2.05){
                        return .portrait
                    }
                    if (angle > 0.0 && angle < 2.05){
                        return .portraitUpsideDown
                    }
                        break;
                case .portraitUpsideDown:
                    if (angle > 2.66){
                        return .landscapeRight
                    }
                    if (angle < 0.48){
                        return .landscapeLeft
                    }
                        break;
                case .portrait:
                    fallthrough
                    default:
                        if (angle > -0.47){
                            return .landscapeLeft
                        }
                        if (angle < -2.64){
                            return .landscapeRight
                        }
                        break;
                }
            }
        }
//        print("deviceOrientation is \(deviceOrientation.rawValue)")
        return deviceOrientation;
    }
    
    func startAccelerometerUpdates() {
        if !self.motionManager.isAccelerometerAvailable {
            print("MotionOrientation - Accelerometer is NOT available")
            return
        }
        self.motionManager.startAccelerometerUpdates(to: operationQueue) {[weak self] (data, error) in
            self?.accelerometerUpdateWithData(data, error: error)
        }
    }
    
    func stopAccelerometerUpdates() {
        self.motionManager.stopAccelerometerUpdates()
    }
}
