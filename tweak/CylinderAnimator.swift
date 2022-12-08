import UIKit

private extension UIView {

    static let perspectiveDistance = (UIScreen.main.bounds.size.width + UIScreen.main.bounds.size.height) / 2

    func rotate(_ angle: CGFloat, _ pitch: CGFloat = 0, _ yaw: CGFloat = 0, _ roll: CGFloat = 1) {
        var transform = layer.transform

        if !pitch.isZero || !yaw.isZero {
            transform.m34 = -1/UIView.perspectiveDistance
        }

        layer.transform = CATransform3DRotate(transform, angle, pitch, yaw, roll)
    }

    func scale(_ percent: CGFloat) {
        var transform = layer.transform
        
        let oldm34 = transform.m34
        transform.m34 = -1/UIView.perspectiveDistance
        transform = CATransform3DScale(transform, percent, percent, 1)
        transform.m34 = oldm34

        layer.transform = transform
    }

    func translate(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) {
        var transform = layer.transform

        let oldm34 = transform.m34
        if abs(z) > 0.01 {
            transform.m34 = -1/UIView.perspectiveDistance
        }

        transform = CATransform3DTranslate(transform, x, y, z)
        transform.m34 = oldm34

        layer.transform = transform
    }

    var width: CGFloat {
        return frame.size.width / layer.transform.m11
    }
     
    var height: CGFloat {
        return frame.size.height / layer.transform.m22
    }
}

@objc(CylinderAnimator) @objcMembers class CylinderAnimator : NSObject {
    
    @nonobjc private static let screenWidth = UIScreen.main.bounds.size.width
    @nonobjc private static let screenHeight = UIScreen.main.bounds.size.height

    static func backwards(_ page: UIView, _ offset: CGFloat) {
        page.translate(2*offset, 0, 0)
    }

    static func cardHorizontal(_ page: UIView, _ offset: CGFloat) {
        page.layer.savePosition()
        page.layer.position.x += offset

        let percent = offset/page.width
        
        if abs(percent) >= 0.5 {
            page.alpha = 0
        }
        
        page.rotate(-CGFloat.pi*percent, 0, 1, 0)
    }

    static func cardVertical(_ page: UIView, _ offset: CGFloat) {
        page.layer.savePosition()
        page.layer.position.x += offset

        let percent = offset/page.width
        
        if abs(percent) >= 0.5 {
            page.alpha = 0
        }
        
        page.rotate(CGFloat.pi*percent, 1, 0, 0)
    }
    
    static func chomp(_ page: UIView, _ offset: CGFloat) {
        var percent = offset/page.width
        
        if percent < 0 {
            percent = -percent
        }
        
        percent *= screenHeight/2
        
        for icon in page.subviews {
            if icon.frame.midY < page.width/2 {
                page.translate(0, -percent, 0)
            }
            else {
                page.translate(0, percent, 0)
            }
        }
    }
    
    @inlinable @discardableResult @nonobjc static func cube(_ page: UIView, _ offset: CGFloat, isInside: Bool) -> (CGFloat, CGFloat, CGFloat) {
        let percent = offset/page.width
        page.layer.savePosition()
        page.layer.position.x += offset
        
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
        
        page.translate(x, 0, z)
        page.rotate(angle, 0, 1, 0)
        
        return (x, z, angle)
    }
    
    static func cubeInside(_ page: UIView, _ offset: CGFloat) {
        cube(page, offset, isInside: true)
    }
    
    static func cubeOutside(_ page: UIView, _ offset: CGFloat) {
        var (x, z, angle) = cube(page, offset, isInside: false)
        let threshold = abs(atan((UIView.perspectiveDistance - z)/x))
        angle = abs(angle)
        
        if angle > threshold {
            page.alpha = 1 - (angle - threshold)/(CGFloat.pi/2 - threshold)
        }
        else {
            page.alpha = 1
        }
    }

    static func doubleDoor(_ page: UIView, _ offset: CGFloat) {
        page.translate(offset, 0, 0)
        
        let percent = abs(offset/page.width)
        
        for icon in page.subviews {
            if icon.frame.midX > page.width/2 {
                icon.translate(percent*page.width, 0, 0)
            }
            else {
                icon.translate(-percent*page.width, 0, 0)
            }
        }
    }
    
    static func hinge(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        page.layer.savePosition()
        page.layer.position.x += offset
        
        let angle = percent*CGFloat.pi
        var x = page.width/2
        if percent > 0 {
            x = -x
        }
        
        page.translate(x, 0, 0)
        page.rotate(angle, 0, 1, 0)
        page.translate(-x, 0, 0)
    }

    static func horizontalAntLines(_ page: UIView, _ offset: CGFloat) {
         let percent = offset/page.width
         
         page.translate(offset, 0, 0)
         page.alpha = 1 - abs(percent)
         
         var direction: CGFloat = 1
         var lastY: CGFloat = 0
         
         for icon in page.subviews {
             if icon.frame.origin.y > lastY  {
                 direction = -direction
                 lastY = icon.frame.origin.y
             }
             icon.translate(direction*offset, 0, 0)
         }
     }

    static func hyperspace(_ page: SBIconListView, _ offset: CGFloat) {
        let percent = abs(offset/page.width)
        let rollup = min(percent * 5, 1)
        let front: CGFloat = (offset > 0) ? 1 : -1
        let runaway = max(min((percent-0.2)/0.7, 1), 0)
        
        let middleX = page.width/2
        let middleY = page.height/2 + 7

        page.enumerateIconViews { icon, _ , _ in
            let iconX = icon.frame.midX
            let iconY = icon.frame.midY

            let angle = atan((middleY-iconY)/(middleX-iconX))
            let side: CGFloat = (middleX < iconX) ? -1 : 1
            let pitch = CGFloat.pi/2.4

            if abs(angle) == CGFloat.pi/2 {
                let side2: CGFloat = (middleX-iconY > 0) ? -1 : 1
                icon.rotate(rollup*pitch*side2, 1, 0)
                icon.translate(-500*runaway*side2*front, 0, 0)
            }
            else {
                icon.rotate(rollup*angle)
            }
            icon.rotate(rollup*pitch*side, 0, 1, 0)
            icon.translate(500*runaway*side*front, 0, 0)
            icon.alpha = 1 - runaway
        }

        page.translate(offset, 0, 0)
    }

    static func leftStairs(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let x = percent * -20
        let z = percent * -100
        
        page.translate(x, 0, z)
    }

    static func iconCollection(_ page: SBIconListView, _ offset: CGFloat) {
        let percent = abs(offset/page.width)
        let centerX = page.width/2
        let centerY = page.height/2

        page.enumerateIconViews { icon, _ , _ in
            let x = icon.frame.midX
            let y = icon.frame.midY
            
            var hypotenuse = percent*hypot(x-centerX, y-centerY)
            let angle = atan((centerX - x) / (centerY - y))
            if y > centerY {
                hypotenuse = -hypotenuse
            }
            
            let dx = hypotenuse * sin(angle)
            let dy = hypotenuse * cos(angle)
            
            icon.translate(dx, dy, 0)
        }
    }
    
    static func pageFade(_ page: UIView, _ offset: CGFloat) {
        let percent = 1 - abs(offset/page.layer.bounds.size.width)
        
        page.alpha = percent
        
        for icon in page.subviews {
            icon.alpha = percent
        }
    }

    static func pageFlip(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        
        let angle = percent*CGFloat.pi
        
        page.alpha = 1 - abs(percent)
        page.rotate(angle, 0, 1, 0)
    }

    static func pageTwist(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        
        let angle = percent*CGFloat.pi
        
        page.alpha = 1 - abs(percent)
        page.rotate(-2/3*angle, 1, 0, 0)
    }

    static func physcospiral(_ page: SBIconListView, _ offset: CGFloat) {
        let percent = abs(offset/page.layer.bounds.size.width)
        let side: CGFloat = (offset > 0) ? 1 : -1

        let rollup = min(percent*5, 1)
        let runaway = max(min((percent-0.20)/0.6, 1), 0)

        let middleX = page.width/2
        let middleY = page.height/2 + 7
        let radiusParts = middleY / CGFloat(page.subviews.count)
        let theta = (3.5*CGFloat.pi) / CGFloat(page.subviews.count)

        page.enumerateIconViews { icon, i , _ in
            let initAngle = CGFloat(i) * theta
            let initRadius = CGFloat(i) * radiusParts
            let angle = initAngle+runaway*(3.5*CGFloat.pi-initAngle)
            let radius = initRadius+runaway*(middleY-initRadius) + 45
            let iconX = icon.frame.midX
            let iconY = icon.frame.midY
            let pathX = middleX + (radius*cos(angle)) * side
            let pathY = middleY + (radius*sin(angle)) * side

            icon.translate(rollup*(pathX-iconX), rollup*(pathY-iconY), 0)
            icon.rotate(rollup * angle)
            let size = min(1-(1-(radius/(middleY+50)))*rollup, 1)
            icon.scale(size*size)
        }

        page.translate(offset, 0, 0)
    }
    
    static func rightStairs(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let x = percent * -20
        let z = percent * 100
        
        page.translate(x, 0, z)
    }
    
    static func scatter(_ page: SBIconListView, _ offset: CGFloat) {
        let percent = abs(offset/page.width)

        page.enumerateIconViews { icon, i , _ in
            if i % 2 == 1 {
                icon.translate(0, percent*page.height/2, 0)
            }
            else {
                icon.translate(0, -percent*page.height/2, 0)
            }
        }
    }

    static func shrink(_ page: UIView, _ offset: CGFloat) {
        let percent = 1 - abs(offset/page.layer.bounds.size.width)
        
        for icon in page.subviews {
            icon.scale(percent)
        }
    }
    
    static func spin(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let angle = percent*CGFloat.pi*2
        
        for icon in page.subviews {
            icon.rotate(angle)
        }
    }
    
    static func suck(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        let fixed = abs(percent)
        let side: CGFloat = (percent > 0) ? 1 : 0
        
        for icon in page.subviews {
            let iconX = icon.frame.midX
            let iconY = icon.frame.midY
            let absX = iconX+side*(screenWidth-2*iconX)
            let pathX = page.width * side
            let pathY = page.height + 7 + icon.height/2
            let iconAngle = atan(iconY/absX)
            
            icon.translate((pathX-iconX)*fixed, (pathY-iconY)*fixed, 0)
            icon.rotate(percent*iconAngle)
            icon.scale(sqrt(-fixed+1))
        }
    }

    static func verticalAntLines(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        
        page.translate(offset, 0, 0)
        page.alpha = 1 - abs(percent)
        
        var direction: CGFloat = 1
        var lastX = page.width
        
        for icon in page.subviews {
            if lastX > icon.frame.origin.x {
                direction = -1
            }
            else {
                direction = -direction
            }
            
            lastX = icon.frame.origin.x
            
            icon.translate(0, direction*percent*page.height, 0)
        }
    }

    static func verticalScrolling(_ page: UIView, _ offset: CGFloat) {
        let percent = offset/page.width
        page.translate(offset, percent*page.height, 0)
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
            
            let begX = icon.frame.midX
            let begY = icon.frame.midY
            
            let endX = centerX+radius*cos(iconAngle)
            let endY = centerY-radius*sin(iconAngle)
            
            icon.translate((endX-begX)*stage1P, (endY-begY)*stage1P, 0)
            icon.rotate(-stage1P*(CGFloat.pi/2 + iconAngle))
        }
        
        page.alpha = 1 - stage2P
        page.translate(offset, 0, 0)
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
                icon.translate(dx, 0, 0)
            }
        }
        
        page.translate(offset, 0, 0)
    }

    static func wheel(_ page: UIView, _ offset: CGFloat) {
        page.layer.savePosition()
        page.layer.position.x += offset

        let percent = offset/page.width

        for icon in page.subviews {
            let iconCenterX = icon.frame.midX
            let iconCenterY = icon.frame.midY
            let iconCenterXOffset = page.width/2 - iconCenterX
            let iconRadius = screenHeight - iconCenterY

            let percent2 = ((offset < 0) ?  iconCenterX : page.width - iconCenterX) / page.width

            let angle = -percent*(1 + percent2*2) * CGFloat.pi/2

            icon.translate(iconCenterXOffset, iconRadius, 0)
            icon.rotate(angle)
            icon.translate(-iconCenterXOffset, -iconRadius, 0)
        }
    }
}
