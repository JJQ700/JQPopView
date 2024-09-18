//
//  UIView+JQPopView.swift
//  GSY
//
//  Created by 纪 on 2024/9/2.
//

import UIKit

extension UIView {
    
    /// 获取/设置view的x坐标
    var pv_X: CGFloat {
        
        get {
            return frame.origin.x
        }
        
        set {
            var frame = frame
            frame.origin.x = newValue
            self.frame = frame
        }
        
    }
    
    /// 获取/设置view的Y坐标
    var pv_Y: CGFloat {
        
        get {
            return frame.origin.y
        }
        
        set {
            var frame = frame
            frame.origin.y = newValue
            self.frame = frame
        }
        
    }
    
    var pv_Width: CGFloat {
        
        get {
            return frame.size.width
        }
        
        set {
            var frame = frame
            frame.size.width = newValue
            self.frame = frame
        }
        
    }
    
    var pv_Height: CGFloat {
        
        get {
            return frame.size.height
        }
        
        set {
            var frame = frame
            frame.size.height = newValue
            self.frame = frame
        }
        
    }
    
    var pv_Size: CGSize {
        
        get {
            return frame.size
        }
        
        set {
            var frame = frame
            frame.size = newValue
            self.frame = frame
        }
        
    }
    
    var pv_CenterX: CGFloat {
        
        get {
            return center.x
        }
        
        set {
            var center = center
            center.x = newValue
            self.center = center
        }
        
    }
    
    var pv_CenterY: CGFloat {
        
        get {
            return center.y
        }
        
        set {
            var center = center
            center.y = newValue
            self.center = center
        }
        
    }
    
    var pv_Top: CGFloat {
        
        get {
            return frame.origin.y
        }
        
        set {
            var frame = frame
            frame.origin.y = newValue
            self.frame = frame
        }
        
    }
    
    var pv_Left: CGFloat {
        
        get {
            return frame.origin.x
        }
        
        set {
            var frame = frame
            frame.origin.x = newValue
            self.frame = frame
        }
        
    }
    
    var pv_Bottom: CGFloat {
        
        get {
            return frame.origin.y + frame.size.height
        }
        
        set {
            var frame = frame
            frame.origin.y = newValue - self.frame.size.height
            self.frame = frame
        }
        
    }
    
    var pv_Right: CGFloat {
        
        get {
            return frame.origin.x + frame.size.width
        }
        
        set {
            var frame = frame
            frame.origin.x = newValue - self.frame.size.width
            self.frame = frame
        }
        
    }
    
    static func keyWindow() -> UIView {
        
        if #available(iOS 13.0, *) {
            
            let array: Set = UIApplication.shared.connectedScenes
            
            for scene in array {
                if scene.isKind(of: UIWindowScene.self) {
                    for windowTemp in (scene as! UIWindowScene).windows {
                        if windowTemp.isKeyWindow {
                            return windowTemp
                        }
                    }
                }
            }
            
        }else {
            return UIApplication.shared.keyWindow!
        }
        
        return UIView()
        
    }
    
}
