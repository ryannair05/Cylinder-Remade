import UIKit

private extension UIView {
    var width: CGFloat {
        return frame.size.width / layer.transform.m11
    }
    
    var height: CGFloat {
        return frame.size.height / layer.transform.m22
    }
}

@objc(CylinderAnimator) @objcMembers class CylinderAnimator : NSObject {
    
    @nonobjc static let screenWidth = UIScreen.main.bounds.size.width
    @nonobjc static let screenHeight = UIScreen.main.bounds.size.height
    @nonobjc static let perspectiveDistance = (UIScreen.main.bounds.size.width + UIScreen.main.bounds.size.height) / 2
    
    static func chomp(_ page: UIView, _ offset: CGFloat) {
        var percent = offset/page.width
        
        if percent < 0 {
            percent = -percent
        }
        
        percent *= screenHeight/2
        
        for icon in page.subviews {
            if icon.frame.origin.y + icon.height/2 < page.width/2 {
                page.layer.transform = translate(page, 0, -percent, 0)
            }
            else {
                page.layer.transform = translate(page, 0, percent, 0)
            }
        }
    }
    
    @inlinable @discardableResult @nonobjc static func cube(_ page: UIView, _ offset: CGFloat, isInside: Bool) -> (CGFloat, CGFloat, CGFloat) {
        let percent = offset/page.width
        page.layer.savePosition()
        page.layer.position.x = page.layer.position.x + offset
        
        var angle = -percent*CGFloat.pi/2
        
        let h = page.width/2
        var x = h*cos(abs(angle)) - h
        var z = -h*sin(abs(angle))
        
        if percent > 0 {
            x = -x
        }
        
        x -= offset
        
        if isInside {
            z = -z
            angle = -angle
        }
        
        page.layer.transform = translate(page, x, 0, z)
        page.layer.transform = rotate(page, angle, 0, 1, 0)
        
        return (x, z, angle)
    }
    
    static func cubeInside(_ page: UIView, _ offset: CGFloat) {
        cube(page, offset, isInside: true)
    }
    
    static func cubeOutside(_ page: UIView, _ offset: CGFloat) {
        var (x, z, angle) = cube(page, offset, isInside: false)
        let threshold = abs(atan((perspectiveDistance - z)/x))
        angle = abs(angle)
        
        if angle > threshold {
            page.alpha = 1 - (angle - threshold)/(CGFloat.pi/2 - threshold)
        }
        else {
            page.alpha = 1
        }
    }
    
    static func hinge(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        page.layer.savePosition()
        page.layer.position.x = page.layer.position.x + offset
        
        let angle = percent*CGFloat.pi
        var x = page.width/2
        if percent > 0 {
            x = -x
        }
        
        page.layer.transform = translate(page, x, 0, 0)
        page.layer.transform = rotate(page, angle, 0, 1, 0)
        page.layer.transform = translate(page, -x, 0, 0)
    }
    
    static func leftStairs(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let x = percent * -20
        let z = percent * -100
        
        page.layer.transform = translate(page, x, 0, z)
    }
    
    static func pageFade(_ page: UIView, _ offset: CGFloat) {
        let percent = 1 - abs(offset/page.layer.bounds.size.width)
        
        page.alpha = percent
        
        for icon in page.subviews {
            icon.alpha = percent
        }
    }
    
    static func rightStairs(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let x = percent * -20
        let z = percent * 100
        
        page.layer.transform = translate(page, x, 0, z)
    }
    
    @inlinable @nonobjc static func rotate(_ icon: UIView, _ angle: CGFloat, _ pitch: CGFloat = 0, _ yaw: CGFloat = 0, _ roll: CGFloat = 1) -> CATransform3D {
        var transform = icon.layer.transform
        
        if abs(pitch) > 0.01 || abs(yaw) > 0.01 {
            transform.m34 = -1/perspectiveDistance
        }
        
        return CATransform3DRotate(transform, angle, pitch, yaw, roll)
    }
    
    @inlinable @nonobjc static func scale(_ icon: UIView, _ percent: CGFloat) -> CATransform3D {
        var transform = icon.layer.transform
        
        let oldm34 = transform.m34
        transform.m34 = -1/perspectiveDistance
        transform = CATransform3DScale(transform, percent, percent, 1)
        transform.m34 = oldm34
        
        return transform
    }
    
    static func shrink(_ page: UIView, _ offset: CGFloat) {
        let percent = 1 - abs(offset/page.layer.bounds.size.width)
        
        for icon in page.subviews {
            icon.layer.transform = scale(icon, percent)
        }
    }
    
    static func spin(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let angle = percent*CGFloat.pi*2
        
        for icon in page.subviews {
            icon.layer.transform = rotate(icon, angle)
        }
    }
    
    static func suck(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let fixed = abs(percent)
        let side: CGFloat = (percent > 0) ? 1 : 0
        
        for icon in page.subviews {
            let iconX = icon.frame.origin.x + icon.width/2
            let iconY = icon.frame.origin.y + icon.height/2
            let absX = iconX+side*(screenWidth-2*iconX)
            let pathX = page.width * side
            let pathY = page.height + 7 + icon.height/2
            let iconAngle = atan(iconY/absX)
            
            icon.layer.transform = translate(icon, (pathX-iconX)*fixed, (pathY-iconY)*fixed, 0)
            icon.layer.transform = rotate(icon, percent*iconAngle)
            icon.layer.transform = scale(icon, sqrt(-fixed+1))
        }
    }
    
    @inlinable @nonobjc static func translate(_ icon: UIView, _ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> CATransform3D {
        var transform = icon.layer.transform
        
        let oldm34 = transform.m34
        if abs(z) > 0.01 {
            transform.m34 = -1/perspectiveDistance
        }
        
        transform = CATransform3DTranslate(transform, x, y, z)
        transform.m34 = oldm34
        
        return transform
    }

    static func verticalScrolling(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        page.layer.transform = translate(page, offset, percent*page.height, 0)
        page.alpha = 1 - abs(percent)
    }
    
    static func vortex(_ page: UIView, _ offset: CGFloat) {
        let percent = abs(offset/page.width)
        
        let centerX = page.width/2
        let centerY = page.height/2 + 7
        var radius = 0.60 * centerX
        if radius > page.height {
            radius = 0.60 * page.height/2
        }
        
        let theta = (2*CGFloat.pi) / CGFloat(page.subviews.count)
        
        let stage1P = min(percent*3, 1)
        let stage2P = max(min((percent*3) - 1, 1), 0)
        
        let stage3P = stage2P*(CGFloat.pi/3)
        let pi_6 = CGFloat.pi/6
        
        for (i, icon) in page.subviews.enumerated() {
            let iconAngle = theta*CGFloat(i) - pi_6 + stage3P
            
            let begX = icon.frame.origin.x + icon.width/2
            let begY = icon.frame.origin.y + icon.height/2
            
            let endX = centerX+radius*cos(iconAngle)
            let endY = centerY-radius*sin(iconAngle)
            
            icon.layer.transform = translate(icon, (endX-begX)*stage1P, (endY-begY)*stage1P, 0)
            icon.layer.transform = rotate(icon, -stage1P*(CGFloat.pi/2 + iconAngle))
        }
        
        page.alpha = 1 - stage2P
        page.layer.transform = translate(page, offset, 0, 0)
    }
    
    static func wave(_ page: UIView, _ offset: CGFloat) {
        let percent = abs(offset/page.width)
        let numIcons = page.subviews.count
        
        for (i, icon) in page.subviews.enumerated() {
            let direction: CGFloat = (offset < 0) ? 1 : -1
            let iconIndex = CGFloat((offset < 0) ? numIcons - i: i - 1)
            
            let curIconPercent = percent - ((0.525 / CGFloat(numIcons)) * iconIndex)
            
            if curIconPercent > 0 {
                let dx = direction*(curIconPercent*pow(3.5, 2))*page.width
                icon.layer.transform = translate(icon, dx, 0, 0)
            }
        }
        
        page.layer.transform = translate(page, offset, 0, 0)
    }
}
