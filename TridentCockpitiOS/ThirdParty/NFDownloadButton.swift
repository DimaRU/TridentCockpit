//
//  NFDownloadButton.swift
//  NFDownloadButton
//
//  Created by Leonardo Cardoso on 20/05/2017.
//  Copyright © 2017 leocardz.com. All rights reserved.
//

import Foundation
import UIKit

public class StyleKit: NSObject {

    // Drawing Methods
    public static func drawToDownloadState(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 50, height: 50), resizing: ResizingBehavior = .aspectFit, palette: Palette, toDownloadManipulable: CGFloat = 0) {
        // General Declarations
        let context = UIGraphicsGetCurrentContext()!

        // Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 50, height: 50), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 50, y: resizedFrame.height / 50)


        // Arrow Download
        context.saveGState()
        context.setAlpha(toDownloadManipulable)
        context.beginTransparencyLayer(auxiliaryInfo: nil)


        // Rectangle 3 Drawing
        let rectangle3Path = UIBezierPath(rect: CGRect(x: 15, y: 36, width: 20, height: 2))
        palette.initialColor.setFill()
        rectangle3Path.fill()


        // Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 24, y: 12))
        bezierPath.addLine(to: CGPoint(x: 24, y: 32.2))
        bezierPath.addLine(to: CGPoint(x: 18.4, y: 26.6))
        bezierPath.addLine(to: CGPoint(x: 17, y: 28))
        bezierPath.addLine(to: CGPoint(x: 25, y: 36))
        bezierPath.addLine(to: CGPoint(x: 33, y: 28))
        bezierPath.addLine(to: CGPoint(x: 31.6, y: 26.6))
        bezierPath.addLine(to: CGPoint(x: 26, y: 32.2))
        bezierPath.addLine(to: CGPoint(x: 26, y: 12))
        bezierPath.addLine(to: CGPoint(x: 24, y: 12))
        palette.initialColor.setFill()
        bezierPath.fill()
        UIColor.black.setStroke()
        bezierPath.lineWidth = 0
        bezierPath.stroke()


        context.endTransparencyLayer()
        context.restoreGState()

        context.restoreGState()

    }

    public static func drawRippleState(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 50, height: 50), resizing: ResizingBehavior = .aspectFit, palette: Palette, rippleManipulable: CGFloat = 0) {
        // General Declarations
        let context = UIGraphicsGetCurrentContext()!

        // Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 50, height: 50), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 50, y: resizedFrame.height / 50)



        // Variable Declarations
        let rippleDimensions: CGFloat = 31 + rippleManipulable * 15
        let rippleOrigin: CGFloat = -1 * rippleDimensions / 2.0
        let rippleAlpha: CGFloat = rippleManipulable < 0.5 ? rippleManipulable : 1 - rippleManipulable
        let requestDownloadSquareAlpha: CGFloat = rippleManipulable
        let requestDownloadReveal: CGFloat = rippleManipulable * 34

        // Dashed Circle Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)

        context.saveGState()
        context.setBlendMode(.destinationAtop)
        context.beginTransparencyLayer(auxiliaryInfo: nil)

        let dashedCirclePath = UIBezierPath()
        dashedCirclePath.move(to: CGPoint(x: 15, y: 0))
        dashedCirclePath.addCurve(to: CGPoint(x: -0, y: 15), controlPoint1: CGPoint(x: 15, y: 8.28), controlPoint2: CGPoint(x: 8.28, y: 15))
        dashedCirclePath.addCurve(to: CGPoint(x: -15, y: 0), controlPoint1: CGPoint(x: -8.28, y: 15), controlPoint2: CGPoint(x: -15, y: 8.28))
        dashedCirclePath.addCurve(to: CGPoint(x: 0, y: -15), controlPoint1: CGPoint(x: -15, y: -8.28), controlPoint2: CGPoint(x: -8.28, y: -15))
        dashedCirclePath.addCurve(to: CGPoint(x: 15, y: 0), controlPoint1: CGPoint(x: 8.28, y: -15), controlPoint2: CGPoint(x: 15, y: -8.28))
        dashedCirclePath.close()
        palette.downloadColor.setStroke()
        dashedCirclePath.lineWidth = 1
        context.saveGState()
        context.setLineDash(phase: 5, lengths: [5, 3.5])
        dashedCirclePath.stroke()
        context.restoreGState()

        context.endTransparencyLayer()
        context.restoreGState()

        context.restoreGState()


        // Reveal Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)
        context.rotate(by: -180 * CGFloat.pi/180)

        context.saveGState()
        context.setBlendMode(.sourceIn)
        context.beginTransparencyLayer(auxiliaryInfo: nil)

        let revealPath = UIBezierPath(rect: CGRect(x: -17, y: -17, width: 34, height: requestDownloadReveal))
        palette.downloadColor.setFill()
        revealPath.fill()

        context.endTransparencyLayer()
        context.restoreGState()
        context.restoreGState()


        // Square Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)
        context.saveGState()
        context.setAlpha(requestDownloadSquareAlpha)

        let squarePath = UIBezierPath(rect: CGRect(x: -3.75, y: -3.75, width: 7.5, height: 7.5))
        palette.downloadColor.setFill()
        squarePath.fill()

        context.restoreGState()
        context.restoreGState()


        // RippleCircle Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)
        context.saveGState()
        context.setAlpha(rippleAlpha)

        let rippleCirclePath = UIBezierPath(ovalIn: CGRect(x: rippleOrigin, y: rippleOrigin, width: rippleDimensions, height: rippleDimensions))
        palette.rippleColor.setStroke()
        rippleCirclePath.lineWidth = 2.5
        rippleCirclePath.stroke()

        context.restoreGState()
        context.restoreGState()

        
        context.restoreGState()

    }

    public static func drawDownloadCompleteState(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 50, height: 50), resizing: ResizingBehavior = .aspectFit, palette: Palette, downloadedManipulable: CGFloat = 0) {
        // General Declarations
        let context = UIGraphicsGetCurrentContext()!

        // Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 50, height: 50), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 50, y: resizedFrame.height / 50)



        // Variable Declarations
        let downloadedCircleOpacity: CGFloat = 1 - downloadedManipulable
        let downloadedCenterDarkCicleDimensions: CGFloat = 11 + (1 - downloadedManipulable) * 15
        let downloadedCenterDarkCicleOrigin: CGFloat = downloadedCenterDarkCicleDimensions / 2.0 * -1

        // Group
        context.saveGState()
        context.translateBy(x: 25, y: 25)

        context.setAlpha(downloadedCircleOpacity)
        context.beginTransparencyLayer(auxiliaryInfo: nil)


        // Full Drawing
        context.saveGState()
        context.translateBy(x: 0.5, y: -0.5)
        context.rotate(by: -90 * CGFloat.pi/180)

        let fullPath = UIBezierPath(ovalIn: CGRect(x: -15, y: -15, width: 29, height: 29))
        palette.downloadColor.setFill()
        fullPath.fill()
        palette.downloadColor.setStroke()
        fullPath.lineWidth = 2
        fullPath.stroke()

        context.restoreGState()


        // Full Center Drawing
        context.saveGState()
        context.translateBy(x: (downloadedCenterDarkCicleOrigin + 13), y: (downloadedCenterDarkCicleOrigin + 13))

        let fullCenterPath = UIBezierPath(ovalIn: CGRect(x: -13.03, y: -12.97, width: downloadedCenterDarkCicleDimensions, height: downloadedCenterDarkCicleDimensions))
        palette.buttonBackgroundColor.setFill()
        fullCenterPath.fill()
        palette.buttonBackgroundColor.setStroke()
        fullCenterPath.lineWidth = 0.5
        fullCenterPath.stroke()

        context.restoreGState()


        // Square Drawing
        context.saveGState()

        context.saveGState()
        context.setAlpha(downloadedCircleOpacity)

        let squarePath = UIBezierPath(rect: CGRect(x: -3.75, y: -3.75, width: 7.5, height: 7.5))
        palette.downloadColor.setFill()
        squarePath.fill()

        context.restoreGState()

        context.restoreGState()


        context.endTransparencyLayer()

        context.restoreGState()

    }

    public static func drawCheckState(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 50, height: 50), resizing: ResizingBehavior = .aspectFit, palette: Palette,  downloadedManipulable: CGFloat = 0, checkRevealManipulable: CGFloat = 0) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!

        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 50, height: 50), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 50, y: resizedFrame.height / 50)

        //// Group
        context.saveGState()
        context.translateBy(x: 25, y: 25)

        // Circle Drawing
//        context.saveGState()
//        let circlePath = UIBezierPath(ovalIn: CGRect(x: -15, y: -15, width: 30, height: 30))
//        palette.downloadColor.setStroke()
//        circlePath.lineWidth = 1
//        circlePath.stroke()
//        context.restoreGState()

        context.beginTransparencyLayer(auxiliaryInfo: nil)

        //// Check Drawing
        let checkPath = UIBezierPath()
        checkPath.move(to: CGPoint(x: -6.29, y: 0.94))
        checkPath.addLine(to: CGPoint(x: -5.38, y: -0.07))
        checkPath.addLine(to: CGPoint(x: -2.65, y: 2.96))
        checkPath.addLine(to: CGPoint(x: 5.09, y: -5.13))
        checkPath.addLine(to: CGPoint(x: 6.45, y: -3.62))
        checkPath.addLine(to: CGPoint(x: -2.65, y: 6))
        checkPath.addLine(to: CGPoint(x: -6.75, y: 1.44))
        checkPath.addLine(to: CGPoint(x: -6.29, y: 0.94))
        checkPath.close()
        palette.deviceColor.setFill()
        checkPath.fill()

        context.endTransparencyLayer()
        context.restoreGState()

        context.restoreGState()

    }

    public static func drawdownloadingState(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 50, height: 50), resizing: ResizingBehavior = .aspectFit, palette: Palette, downloadingManipulable: CGFloat = 0) {
        // General Declarations
        let context = UIGraphicsGetCurrentContext()!

        // Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 50, height: 50), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 50, y: resizedFrame.height / 50)



        // Variable Declarations
        let downloadingAngle: CGFloat = downloadingManipulable == 1 ? -360 : 360 - downloadingManipulable * 360

        // Dashed Circle Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)

        let dashedCirclePath = UIBezierPath()
        dashedCirclePath.move(to: CGPoint(x: 15, y: 0))
        dashedCirclePath.addCurve(to: CGPoint(x: -0, y: 15), controlPoint1: CGPoint(x: 15, y: 8.28), controlPoint2: CGPoint(x: 8.28, y: 15))
        dashedCirclePath.addCurve(to: CGPoint(x: -15, y: 0), controlPoint1: CGPoint(x: -8.28, y: 15), controlPoint2: CGPoint(x: -15, y: 8.28))
        dashedCirclePath.addCurve(to: CGPoint(x: 0, y: -15), controlPoint1: CGPoint(x: -15, y: -8.28), controlPoint2: CGPoint(x: -8.28, y: -15))
        dashedCirclePath.addCurve(to: CGPoint(x: 15, y: 0), controlPoint1: CGPoint(x: 8.28, y: -15), controlPoint2: CGPoint(x: 15, y: -8.28))
        dashedCirclePath.close()
        palette.buttonBackgroundColor.setFill()
        dashedCirclePath.fill()
        palette.downloadColor.setStroke()
        dashedCirclePath.lineWidth = 1
        dashedCirclePath.stroke()

        context.restoreGState()


        // Download Tack Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)
        context.rotate(by: -90 * CGFloat.pi/180)

        let downloadTackRect = CGRect(x: -14, y: -14, width: 28, height: 28)
        let downloadTackPath = UIBezierPath()
        downloadTackPath.addArc(withCenter: CGPoint(x: downloadTackRect.midX, y: downloadTackRect.midY), radius: downloadTackRect.width / 2, startAngle: 0 * CGFloat.pi/180, endAngle: -downloadingAngle * CGFloat.pi/180, clockwise: true)

        palette.downloadColor.setStroke()
        downloadTackPath.lineWidth = 2.5
        downloadTackPath.stroke()

        context.restoreGState()


        // Square Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)

        let squarePath = UIBezierPath(rect: CGRect(x: -3.75, y: -3.75, width: 7.5, height: 7.5))
        palette.downloadColor.setFill()
        squarePath.fill()

        context.restoreGState()
        context.restoreGState()

    }

    public static func drawDashMoveState(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 50, height: 50), resizing: ResizingBehavior = .aspectFit, palette: Palette, dashMoveManipulable: CGFloat = 0) {
        // General Declarations
        let context = UIGraphicsGetCurrentContext()!

        // Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 50, height: 50), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 50, y: resizedFrame.height / 50)



        // Variable Declarations
        let dashMoveCircleRotation: CGFloat = dashMoveManipulable * 15 * -1
        let dashMoveDashedCircleDash: CGFloat = abs(dashMoveCircleRotation) > 15 ? 0 : 5
        let dashMoveDashedCircleGap: CGFloat = abs(dashMoveCircleRotation) >= 15 ? 0 : 3.5
        let dashMoveDashedCirclePhase: CGFloat = abs(dashMoveCircleRotation) > 15 ? 0 : 5

        // Moving Dashed Circle Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)
        context.rotate(by: -dashMoveCircleRotation * CGFloat.pi/180)

        let movingDashedCirclePath = UIBezierPath(ovalIn: CGRect(x: -15, y: -15, width: 30, height: 30))
        palette.downloadColor.setStroke()
        movingDashedCirclePath.lineWidth = 1
        context.saveGState()
        context.setLineDash(phase: dashMoveDashedCirclePhase, lengths: [dashMoveDashedCircleDash, dashMoveDashedCircleGap])
        movingDashedCirclePath.stroke()
        context.restoreGState()

        context.restoreGState()


        // Dashed Circle Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)

        let dashedCirclePath = UIBezierPath()
        dashedCirclePath.move(to: CGPoint(x: 15, y: 0))
        dashedCirclePath.addCurve(to: CGPoint(x: -0, y: 15), controlPoint1: CGPoint(x: 15, y: 8.28), controlPoint2: CGPoint(x: 8.28, y: 15))
        dashedCirclePath.addCurve(to: CGPoint(x: -15, y: 0), controlPoint1: CGPoint(x: -8.28, y: 15), controlPoint2: CGPoint(x: -15, y: 8.28))
        dashedCirclePath.addCurve(to: CGPoint(x: 0, y: -15), controlPoint1: CGPoint(x: -15, y: -8.28), controlPoint2: CGPoint(x: -8.28, y: -15))
        dashedCirclePath.addCurve(to: CGPoint(x: 15, y: 0), controlPoint1: CGPoint(x: 8.28, y: -15), controlPoint2: CGPoint(x: 15, y: -8.28))
        dashedCirclePath.close()
        palette.downloadColor.setStroke()
        dashedCirclePath.lineWidth = 1
        context.saveGState()
        context.setLineDash(phase: 5, lengths: [5, 3.5])
        dashedCirclePath.stroke()
        context.restoreGState()

        context.restoreGState()


        // Square Drawing
        context.saveGState()
        context.translateBy(x: 25, y: 25)

        let squarePath = UIBezierPath(rect: CGRect(x: -3.75, y: -3.75, width: 7.5, height: 7.5))
        palette.downloadColor.setFill()
        squarePath.fill()

        context.restoreGState()
        context.restoreGState()
    }


    @objc(StyleKitResizingBehavior)
    public enum ResizingBehavior: Int {
        case aspectFit /// The content is proportionally resized to fit into the target rectangle.
        case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case stretch /// The content is stretched to match the entire target rectangle.
        case center /// The content is centered in the target rectangle, but it is NOT resized.

        public func apply(rect: CGRect, target: CGRect) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }

            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)

            switch self {
            case .aspectFit:
                scales.width = min(scales.width, scales.height)
                scales.height = scales.width
            case .aspectFill:
                scales.width = max(scales.width, scales.height)
                scales.height = scales.width
            case .stretch:
                break
            case .center:
                scales.width = 1
                scales.height = 1
            }

            var result = rect.standardized
            result.size.width *= scales.width
            result.size.height *= scales.height
            result.origin.x = target.minX + (target.width - result.width) / 2
            result.origin.y = target.minY + (target.height - result.height) / 2
            return result
        }
    }

}

internal class Flow {

    // MARK: - Functions
    // Execute code block asynchronously
    static func async(block: @escaping () -> Void) {

        DispatchQueue.main.async(execute: block)

    }

    // Execute code block asynchronously after given delay time
    static func delay(for delay: TimeInterval, block: @escaping () -> Void) {

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: block)

    }

}

open class Palette {

    var initialColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
    var rippleColor: UIColor = UIColor(red: 0.572, green: 0.572, blue: 0.572, alpha: 1.000)
    var buttonBackgroundColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
    var downloadColor: UIColor = UIColor(red: 0.145, green: 0.439, blue: 0.733, alpha: 1.000)
    var deviceColor: UIColor = UIColor(red: 0.145, green: 0.439, blue: 0.733, alpha: 1.000)

    public init(initialColor: UIColor? = nil, rippleColor: UIColor? = nil, buttonBackgroundColor: UIColor? = nil, downloadColor: UIColor? = nil, deviceColor: UIColor? = nil) {

        self.initialColor = initialColor ?? self.initialColor
        self.rippleColor = rippleColor ?? self.rippleColor
        self.buttonBackgroundColor = buttonBackgroundColor ?? self.buttonBackgroundColor
        self.downloadColor = downloadColor ?? self.downloadColor
        self.deviceColor = deviceColor ?? self.deviceColor

    }

}

public enum NFDownloadButtonState: String {

    case toDownload = "toDownload"
    case willDownload = "willDownload"
    case downloading = "downloading"
    case downloaded = "downloaded"
}

class NFDownloadButtonLayer: CALayer {

    // MARK: - Properties
    @NSManaged var toDownloadManipulable: CGFloat
    @NSManaged var rippleManipulable: CGFloat
    @NSManaged var dashMoveManipulable: CGFloat
    @NSManaged var downloadingManipulable: CGFloat
    @NSManaged var downloadedManipulable: CGFloat
    @NSManaged var checkRevealManipulable: CGFloat

    // MARK: - Initializers
    override init() {

        super.init()

        toDownloadManipulable = 0.0
        rippleManipulable = 0.0
        dashMoveManipulable = 0.0
        downloadingManipulable = 0.0
        downloadedManipulable = 0.0
        checkRevealManipulable = 0.0

    }

    override init(layer: Any) {

        super.init(layer: layer)

        if let layer = layer as? NFDownloadButtonLayer {

            toDownloadManipulable = layer.toDownloadManipulable
            rippleManipulable = layer.rippleManipulable
            dashMoveManipulable = layer.dashMoveManipulable
            downloadingManipulable = layer.downloadingManipulable
            downloadedManipulable = layer.downloadedManipulable
            checkRevealManipulable = layer.checkRevealManipulable

        }

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Lifecyle
    override class func needsDisplay(forKey key: String?) -> Bool {
        guard let key = key else { return false }
        if NFDownloadButtonLayer.isCompatible(key) {
            return true
        }

        return super.needsDisplay(forKey: key)
    }

    override func action(forKey event: String?) -> CAAction? {
        guard let event = event else { return nil }
        if NFDownloadButtonLayer.isCompatible(event) {
            let animation = CABasicAnimation.init(keyPath: event)
            animation.fromValue = presentation()?.value(forKey: event)
            return animation
        }

        return super.action(forKey: event)
    }

    // MARK: - Functions
    private static func isCompatible(_ key: String) -> Bool {

        return key == "toDownloadManipulable" ||
            key == "rippleManipulable" ||
            key == "dashMoveManipulable" ||
            key == "downloadingManipulable" ||
            key == "downloadedManipulable" ||
            key == "checkRevealManipulable"
    }
}

public protocol NFDownloadButtonDelegate {
    func stateChanged(button: NFDownloadButton, newState: NFDownloadButtonState)
}


@IBDesignable
open class NFDownloadButton: UIButton {

    // MARK: - IBDesignable and IBInspectable
    @IBInspectable open var isDownloaded: Bool = false {
        willSet {
            if newValue {
                animate(keyPath: "downloadedManipulable")
                animate(keyPath: "checkRevealManipulable")
            }
        }
    }

    @IBInspectable open var buttonBackgroundColor: UIColor? {
        didSet {
            palette.buttonBackgroundColor = buttonBackgroundColor ?? palette.buttonBackgroundColor
        }
    }

    @IBInspectable open var initialColor: UIColor? {
        didSet {
            palette.initialColor = initialColor ?? palette.initialColor
        }
    }

    @IBInspectable open var rippleColor: UIColor? {
        didSet {
            palette.rippleColor = rippleColor ?? palette.rippleColor
        }
    }

    @IBInspectable open var downloadColor: UIColor? {
        didSet {
            palette.downloadColor = downloadColor ?? palette.downloadColor
        }
    }

    @IBInspectable open var deviceColor: UIColor? {
        didSet {
            palette.deviceColor = deviceColor ?? palette.deviceColor
        }
    }

    override open class var layerClass: AnyClass {
        return NFDownloadButtonLayer.self
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        draw()
    }

    public init(frame: CGRect, isDownloaded: Bool = false, palette: Palette = Palette()) {
        super.init(frame: frame)

        self.isDownloaded = isDownloaded
        self.palette = palette

        draw()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Lifecyle
    override open func awakeFromNib() {
        draw()
    }


    // MARK: - Properties
    var keyPath: String = "toDownloadManipulable"
    open var palette: Palette = Palette()
    open var delegate: NFDownloadButtonDelegate?
    open var progress: Float = 0.0 {
        willSet {
            guard let layer: NFDownloadButtonLayer = layer as? NFDownloadButtonLayer else { return }
            var targetValue = newValue
            if newValue >= 1.0 {
                targetValue = 1
                Flow.delay(for: 0.5) {
                    self.downloadState = .downloaded
                    layer.downloadingManipulable = 0.0
                }

            }
            animate(duration: 0.5, from: layer.downloadingManipulable, to: CGFloat(targetValue), keyPath: "downloadingManipulable")
        }
    }

    open var downloadState: NFDownloadButtonState? {
        willSet {
            guard
                let newValue: NFDownloadButtonState = newValue,
                !isDownloaded else { return }
            switch newValue {
            case .toDownload:
                resetManipulables()
                Flow.async {
                    self.animate(keyPath: "toDownloadManipulable")
                }
            case .willDownload:
                Flow.async {
                    self.animate(duration: 1, keyPath: "rippleManipulable")
                }
            case .downloading:
                Flow.async {
                    self.animate(to: 0, keyPath: "downloadingManipulable")
                }
            case .downloaded:
                Flow.async {
                    self.animate(duration: 1, keyPath: "downloadedManipulable")
                }
                
            }
        }

    }

    override open func draw(_ layer: CALayer, in ctx: CGContext) {

        super.draw(layer, in: ctx)

        guard
            let layer: NFDownloadButtonLayer = layer as? NFDownloadButtonLayer
            else { return }

        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: layer.frame.size)

        UIGraphicsPushContext(ctx)

        switch keyPath {
        case "toDownloadManipulable":  StyleKit.drawToDownloadState(frame: frame, palette: palette, toDownloadManipulable: layer.toDownloadManipulable)
        case "rippleManipulable":      StyleKit.drawRippleState(frame: frame, palette: palette, rippleManipulable: layer.rippleManipulable)
        case "dashMoveManipulable":    StyleKit.drawDashMoveState(frame: frame, palette: palette, dashMoveManipulable: layer.dashMoveManipulable)
        case "downloadingManipulable": StyleKit.drawdownloadingState(frame: frame, palette: palette, downloadingManipulable: layer.downloadingManipulable)
        case "downloadedManipulable":  StyleKit.drawDownloadCompleteState(frame: frame, palette: palette, downloadedManipulable: layer.downloadedManipulable)
        case "checkRevealManipulable": StyleKit.drawCheckState(frame: frame, palette: palette, checkRevealManipulable: layer.checkRevealManipulable)
        default:
            break
        }

        UIGraphicsPopContext()

    }

    // MARK: - Functions
    private func resetManipulables() {

        guard let layer: NFDownloadButtonLayer = layer as? NFDownloadButtonLayer else { return }

        layer.toDownloadManipulable = 0.0
        layer.rippleManipulable = 0.0
        layer.dashMoveManipulable = 0.0
        layer.downloadingManipulable = 0.0
        layer.downloadedManipulable = 0.0
        layer.checkRevealManipulable = 0.0
        
    }
    
    func draw() {
        downloadState = downloadState ?? .toDownload
        needsDisplay()
    }
    
    func needsDisplay() {
        
        layer.contentsScale = UIScreen.main.scale
        layer.setNeedsDisplay()
        
    }
    
    fileprivate func animate(duration: TimeInterval = 0, delay: TimeInterval = 0, from: CGFloat = 0, to: CGFloat = 1, keyPath: String) -> Void {
        
        guard let layer: NFDownloadButtonLayer = layer as? NFDownloadButtonLayer else { return }
        
        self.keyPath = keyPath
        
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.beginTime = CACurrentMediaTime() + delay
        animation.duration = duration
        animation.fillMode = CAMediaTimingFillMode.both
        animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeOut)
        animation.fromValue = from
        animation.toValue = to
        animation.delegate = self
        
        layer.add(animation, forKey: nil)
        
        Flow.async {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.updateManipulable(layer, keyPath, to)
            CATransaction.commit()
        }
        
    }
    
    private func updateManipulable(_ layer: NFDownloadButtonLayer, _ keyPath: String, _ value: CGFloat) {
        
        switch keyPath {
        case "toDownloadManipulable":
            layer.toDownloadManipulable = value
        case "rippleManipulable":
            layer.rippleManipulable = value
        case "dashMoveManipulable":
            layer.dashMoveManipulable = value
        case "downloadingManipulable":
            layer.downloadingManipulable = value
        case "downloadedManipulable":
            layer.downloadedManipulable = value
        case "checkRevealManipulable":
            layer.checkRevealManipulable = value
        default:
            return
        }
    }

    
}

extension NFDownloadButton: CAAnimationDelegate {
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
         
         guard let keyPath = (anim as? CABasicAnimation)?.keyPath else { return }
         switch keyPath {
         case "rippleManipulable":
             animate(duration: 1, keyPath: "dashMoveManipulable")
         case "downloadedManipulable":
             if !isDownloaded {
                 animate(duration: 0.5, keyPath: "checkRevealManipulable")
             }
         default:
             break
         }
         
         switch keyPath {
         case "toDownloadManipulable":
             delegate?.stateChanged(button: self, newState: .toDownload)
         case "rippleManipulable":
             delegate?.stateChanged(button: self, newState: .willDownload)
         case "dashMoveManipulable":
             delegate?.stateChanged(button: self, newState: .downloading)
         case "checkRevealManipulable":
             delegate?.stateChanged(button: self, newState: .downloaded)
         default:
             break
         }
     }

}
