/////
////  TouchJoystickView.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

protocol TouchJoystickViewDelegate: class {
    func joystickDidMove(_ joystickView: TouchJoystickView, to x: Float, y: Float)
    func joystickEndMoving(_ joystickView: TouchJoystickView)
}

@IBDesignable
class TouchJoystickView: UIView {
    enum JoystickType {
        case horizontal
        case vertical
        case dualAxis
    }
    
    @IBInspectable var lineWidth: CGFloat = 2
    @IBInspectable var stickFraction: CGFloat = 0.2
    @IBInspectable var circleColor: UIColor = UIColor.white.withAlphaComponent(0.25)
    @IBInspectable var stickColor: UIColor = UIColor.white
    @IBInspectable var axisColor: UIColor = UIColor(red:0.1, green:0.1, blue:0.1, alpha:1.00)
    @IBInspectable var shadowBlur: CGFloat = 12
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 7, height: 7)
    @IBInspectable var joystickSize: CGSize = .zero

    weak var delegate: TouchJoystickViewDelegate?
    private weak var startTouch: UITouch?
    private var feedbackGenerator : UIImpactFeedbackGenerator? = nil
    private var joystickType: JoystickType = .dualAxis
    private var stickPosition: CGPoint = .zero
    private var stickRadius: CGFloat = 0
    private var highMark = false
    private var lowXMark = false
    private var lowYMark = false
    private var deadzone: CGFloat = 4
    private var joystickBounds: CGRect = .zero

    // MARK: Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    #if TARGET_INTERFACE_BUILDER
    override func prepareForInterfaceBuilder() {
        setup()
    }
    #endif
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup(joystick size: CGSize) {
        joystickSize = size
        setup()
    }

    private func setup() {
        let size = joystickSize != .zero ? joystickSize : bounds.size
        joystickBounds = CGRect(origin: CGPoint(x: bounds.midX - size.width/2, y: bounds.midY - size.height/2), size: size)
        if size.height == size.width {
            joystickType = .dualAxis
        } else {
            joystickType = size.height > size.width ? .vertical : .horizontal
        }
        
        stickRadius = max(joystickBounds.width, joystickBounds.height) * stickFraction / 2
        stickPosition = CGPoint(x: joystickBounds.midX, y: joystickBounds.midY)
    }
    
    // MARK: draw
    override func draw(_ rect: CGRect) {
        if joystickType ~= .dualAxis {
            drawDualAxis(rect)
        } else {
            drawSingleAxis(rect)
        }
    }
    
    private func drawDualAxis(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        let path = UIBezierPath(ovalIn: joystickBounds)
        path.close()
        circleColor.setFill()
        path.fill()

        let pathAxis = UIBezierPath()
        pathAxis.move(to: CGPoint(x: joystickBounds.minX + 0.5, y: joystickBounds.midX))
        pathAxis.addLine(to: CGPoint(x: joystickBounds.maxX - 0.5, y: joystickBounds.midX))
        pathAxis.move(to: CGPoint(x: joystickBounds.midX, y: joystickBounds.minY + 0.5))
        pathAxis.addLine(to: CGPoint(x: joystickBounds.midX, y: joystickBounds.maxY - 0.5))
        pathAxis.close()
        axisColor.setStroke()
        pathAxis.lineWidth = lineWidth
        pathAxis.stroke()

        context.setShadow(offset: shadowOffset, blur: shadowBlur)
        let stickPath = UIBezierPath(arcCenter: stickPosition, radius: stickRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        stickPath.close()
        stickColor.setFill()
        stickPath.fill()
    }

    private func drawSingleAxis(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        let roundedSide = min(joystickBounds.width, joystickBounds.height) / 2
        let path = UIBezierPath(roundedRect: joystickBounds, cornerRadius: roundedSide)
        path.close()
        circleColor.setFill()
        path.fill()
        
        let path1: UIBezierPath
        let path2: UIBezierPath
        let pathAxis = UIBezierPath()
        switch joystickType {
        case .vertical:
            pathAxis.move(to: CGPoint(x: joystickBounds.minX + 0.5, y: joystickBounds.midY))
            pathAxis.addLine(to: CGPoint(x: joystickBounds.maxX - 0.5, y: joystickBounds.midY))
            path1 = UIBezierPath(rect: CGRect(x: joystickBounds.minX + 0.5, y: joystickBounds.minY + roundedSide, width: joystickBounds.width - 1, height: 0.5))
            path2 = UIBezierPath(rect: CGRect(x: joystickBounds.minX + 0.5, y: joystickBounds.maxY - roundedSide, width: joystickBounds.width - 1, height: 0.5))
        case .horizontal:
            pathAxis.move(to: CGPoint(x: joystickBounds.midX, y: joystickBounds.minY + 0.5))
            pathAxis.addLine(to: CGPoint(x: joystickBounds.midX, y: joystickBounds.maxY - 0.5))
            path1 = UIBezierPath(rect: CGRect(x: joystickBounds.minX + roundedSide, y: joystickBounds.minY + 0.5, width: 0.5, height: joystickBounds.height - 1))
            path2 = UIBezierPath(rect: CGRect(x: joystickBounds.maxX - roundedSide, y: joystickBounds.minY + 0.5, width: 0.5, height: joystickBounds.height - 1))
        case .dualAxis:
            fatalError()
        }
        
        path1.close(); path2.close()
        UIColor.white.setFill()
        path1.fill(); path2.fill()

        pathAxis.close()
        axisColor.setStroke()
        pathAxis.lineWidth = lineWidth
        pathAxis.stroke()

        context.setShadow(offset: shadowOffset, blur: shadowBlur)
        let stickPath = UIBezierPath(arcCenter: stickPosition, radius: stickRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        stickPath.close()
        stickColor.setFill()
        stickPath.fill()
    }
    
    // MARK: Control
    func touchBegan(touch: UITouch) {
        guard let superview = superview else { return }
        center = touch.location(in: superview)
        isHidden = false
        startTouch = touch
        stickPosition = touch.location(in: self)
        setNeedsDisplay()
        delegate?.joystickDidMove(self, to: 0, y: 0)
        feedbackGenerator = .init(style: .light)
        feedbackGenerator?.prepare()
        lowXMark = true
        lowYMark = true
        highMark = false
    }
    
    private func highLevelFeedback() {
        guard !highMark else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        highMark = true
    }
    
    func touchMoved(touch: UITouch) {
        guard touch == startTouch else { return }
        var location = touch.location(in: self)
        var xValue: CGFloat = 0
        var yValue: CGFloat = 0
        let lastPosition = stickPosition
        
        switch joystickType {
        case .vertical:
            let radius = joystickBounds.height / 2 - stickRadius
            location.y -= joystickBounds.origin.y
            if abs(location.y - joystickBounds.height / 2) < deadzone {
                yValue = 0
                if !lowYMark {
                    feedbackGenerator?.impactOccurred()
                    feedbackGenerator?.prepare()
                    lowYMark = true
                }
            } else {
                lowYMark = false
                yValue = 1.0 - (location.y - stickRadius) / radius
            }

            if abs(yValue) >= 1 {
                yValue = yValue > 0 ? 1 : -1
                location.y = (-yValue + 1) * radius + stickRadius
                highLevelFeedback()
            } else {
                highMark = false
            }
            stickPosition.y = location.y + joystickBounds.origin.y

        case .horizontal:
            let radius = joystickBounds.width / 2 - stickRadius
            location.x -= joystickBounds.origin.x
            if abs(location.x - joystickBounds.width / 2) < deadzone {
                xValue = 0
                if !lowXMark {
                    feedbackGenerator?.impactOccurred()
                    feedbackGenerator?.prepare()
                    lowXMark = true
                }
            } else {
                lowXMark = false
                xValue = (location.x - stickRadius) / radius - 1.0
            }
            
            if abs(xValue) >= 1 {
                xValue = xValue > 0 ? 1 : -1
                location.x = (xValue + 1) * radius + stickRadius
                highLevelFeedback()
            } else {
                highMark = false
            }
            stickPosition.x = location.x + joystickBounds.origin.x

        case .dualAxis:
            let radius = joystickBounds.width / 2 - stickRadius
            location.x -= joystickBounds.origin.x
            location.y -= joystickBounds.origin.y

            if abs(location.x - joystickBounds.width / 2) < deadzone {
                xValue = 0
                if !lowXMark {
                    feedbackGenerator?.impactOccurred()
                    feedbackGenerator?.prepare()
                    lowXMark = true
                }
            } else {
                lowXMark = false
                xValue = (location.x - stickRadius) / radius - 1.0
            }
            
            if abs(location.y - joystickBounds.height / 2) < deadzone {
                yValue = 0
                if !lowYMark {
                    feedbackGenerator?.impactOccurred()
                    feedbackGenerator?.prepare()
                    lowYMark = true
                }
            } else {
                lowYMark = false
                yValue = 1.0 - (location.y - stickRadius) / radius
            }
            
            let r = sqrt(xValue * xValue + yValue * yValue) * radius
            if r >= radius {
                xValue = radius * (xValue / r)
                yValue = radius * (yValue / r)
                
                location.x = (xValue + 1) * radius + stickRadius
                location.y = (-yValue + 1) * radius + stickRadius

                highLevelFeedback()
            } else {
                highMark = false
            }
            location.x += joystickBounds.origin.x
            location.y += joystickBounds.origin.y

            stickPosition = location
        }
        
        if lastPosition != stickPosition {
            setNeedsDisplay()
            delegate?.joystickDidMove(self, to: Float(xValue), y: Float(yValue))
        }
    }
    
    func touchEnded(touch: UITouch) {
        guard touch == startTouch else { return }
        isHidden = true
        feedbackGenerator = nil
        delegate?.joystickEndMoving(self)
    }
    
}
