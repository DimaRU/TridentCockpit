/////
////  SmartDownloadButton.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

@IBDesignable
final class SmartDownloadButton: UIButton {
    @IBInspectable var trackCircleColor: UIColor = UIColor.systemGray {
        didSet {
            progressView.trackCircleColor = trackCircleColor
        }
    }
    @IBInspectable var lineWidth: CGFloat = 2 {
        didSet {
            spinnerView.lineWidth = lineWidth
            progressView.lineWidth = lineWidth
        }
    }

    public var transitionAnimationDuration: TimeInterval = 0.2

    
    public enum DownloadState {
        case start
        case wait
        case run
        case end
    }
    
    public var downloadState = DownloadState.start {
        didSet {
            guard let imageView = imageView else { return }
            switch oldValue {
            case .start:
                break
            case .wait:
                spinnerView.stopSpinning()
            case .run:
                break
            case .end:
                break
            }
            switch downloadState {
            case .start:
                isUserInteractionEnabled = true
                isSelected = false
                imageView.alpha = 1
                spinnerView.alpha = 0
                progressView.alpha = 0
            case .wait:
                isUserInteractionEnabled = false
                spinnerView.startSpinning()
                progressView.alpha = 0
                imageView.alpha = 0
                spinnerView.alpha = 1
            case .run:
                isUserInteractionEnabled = false
                imageView.alpha = 0
                spinnerView.alpha = 0
                progressView.alpha = 1
            case .end:
                isUserInteractionEnabled = false
                isSelected = true
                imageView.alpha = 1
                spinnerView.alpha = 0
                progressView.alpha = 0
            }
        }
    }
    
    private let spinnerView = SmartDownloadButton.CircleView(drawBackgroundShape: false)
    private let progressView = SmartDownloadButton.CircleView(drawBackgroundShape: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepare()
    }
    
    private func prepare() {
        guard let imageView = imageView else { return }
        spinnerView.frame = imageView.frame
        spinnerView.lineWidth = lineWidth
        spinnerView.circleColor = tintColor
        addSubview(spinnerView)

        progressView.frame = imageView.frame
        progressView.trackCircleColor = trackCircleColor
        progressView.lineWidth = lineWidth
        progressView.circleColor = tintColor
        addSubview(progressView)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        spinnerView.lineWidth = lineWidth
        spinnerView.circleColor = tintColor
        progressView.trackCircleColor = trackCircleColor
        progressView.lineWidth = lineWidth
        progressView.circleColor = tintColor
    }
    
    func trasition(to newState: DownloadState) {
        guard downloadState != newState else { return }
        let oldState = downloadState

        // Prepare for animate transition
        switch newState {
        case .start:
            break
        case .wait:
            break
        case .run:
            progress = 0
            progressView.circleLayer.strokeEnd = 0
        case .end:
            break
        }
        switch (oldState, newState) {
        case (.start, .wait),
             (.start, .run),
             (.run, .end):
            let fromView = presentedView(for: oldState)
            let toView = presentedView(for: newState)
            animateTransition(from: fromView, to: toView, newState: newState) { ended in
                self.downloadState = newState
            }
        default:
            self.downloadState = newState
        }
    }

    private func presentedView(for state: DownloadState) -> UIView {
        switch state {
        case .start : return imageView!
        case .wait  : return spinnerView
        case .run   : return progressView
        case .end   : return imageView!
        }
    }

    var progress: Float = 0 {
        didSet {
            guard downloadState == .run else {
                if progress == 0 {
                    progressView.circleLayer.strokeEnd = 0
                }
                return
            }
            if progress > 1 {
                progress = 1
            }
            if progress == 1 && progressView.isAnimating {
                if let currentAnimatedProgress = progressView.circleLayer.presentation()?.strokeEnd {
                    progressView.circleLayer.strokeEnd = currentAnimatedProgress
                    progressView.animateProgress(from: currentAnimatedProgress, to: CGFloat(progress))
                }
            }
            guard !progressView.isAnimating else { return }
            progressView.animateProgress(from: progressView.circleLayer.strokeEnd, to: CGFloat(progress))
        }
    }
    
    private func animateTransition(from: UIView, to: UIView, newState: DownloadState, completion: @escaping (Bool) -> Void) {
        if from === to {
            UIView.animate(withDuration: transitionAnimationDuration, animations: {
                self.isSelected = newState == .end
            }, completion: completion)
        } else {
            from.alpha = 1
            to.alpha = 0
            UIView.animate(withDuration: transitionAnimationDuration, animations: {
                from.alpha = 0
                to.alpha = 1
                self.isSelected = newState == .end
            }, completion: completion)
        }
    }

    
    final class CircleView: UIView, CAAnimationDelegate {
        
        // MARK: Properties
        private let drawBackgroundShape: Bool
        var isAnimating = false
        var progressAnimationDuration: TimeInterval = 0.3
        let startAngleRadians: CGFloat
        let endAngleRadians: CGFloat
        
        var lineWidth: CGFloat = 3 {
            didSet {
                circleLayer.lineWidth = lineWidth
            }
        }
        var circleColor: UIColor = UIColor.systemBlue {
            didSet {
                circleLayer.strokeColor = circleColor.cgColor
            }
        }
        var trackCircleColor: UIColor = UIColor.systemGray
        
        let circleLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.lineCap = .round
            return layer
        }()
        
        // MARK: Initializers

        init(drawBackgroundShape: Bool) {
            self.drawBackgroundShape = drawBackgroundShape
            if drawBackgroundShape {
                // progress
                startAngleRadians = -CGFloat.pi / 2
                endAngleRadians = startAngleRadians + 2 * .pi
                circleLayer.strokeEnd = 0
            } else {
                // spinner
                startAngleRadians = -CGFloat.pi / 2
                endAngleRadians = startAngleRadians + 12 * .pi / 7
            }
            super.init(frame: .zero)
            autoresizingMask = [.flexibleWidth, .flexibleHeight]
            alpha = 0
            isOpaque = false
            circleLayer.strokeColor = circleColor.cgColor
            circleLayer.lineWidth = lineWidth
            layer.addSublayer(circleLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let radius = min(frame.width / 2, frame.height / 2) - lineWidth / 2
            let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
            circleLayer.path = UIBezierPath(arcCenter: center,
                                            radius: radius,
                                            startAngle: startAngleRadians,
                                            endAngle: endAngleRadians,
                                            clockwise: true).cgPath
        }
        
        func startSpinning() {
            let animationKey = "rotation"
            layer.removeAnimation(forKey: animationKey)
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = CGFloat.pi * 2
            rotationAnimation.duration = 2
            rotationAnimation.repeatCount = .greatestFiniteMagnitude;
            layer.add(rotationAnimation, forKey: animationKey)
        }

        func stopSpinning() {
            let animationKey = "rotation"
            layer.removeAnimation(forKey: animationKey)
        }

        func animateProgress(from startValue: CGFloat, to endValue: CGFloat) {
            isAnimating = true
            circleLayer.strokeEnd = endValue
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animation.fromValue = startValue
            animation.duration = progressAnimationDuration
            animation.delegate = self
            circleLayer.add(animation, forKey: "strokeEnd")
        }
        
        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            isAnimating = !flag
        }
        
        override func draw(_ rect: CGRect) {
            guard drawBackgroundShape else { return }
            let context = UIGraphicsGetCurrentContext()!
            context.clear(rect)
            let radius = min(frame.width / 2, frame.height / 2) - lineWidth / 2
            let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
            trackCircleColor.setStroke()
            circleColor.setFill()
            let trackCirclePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi*2, clockwise: true)
            trackCirclePath.lineWidth = lineWidth
            trackCirclePath.close()
            trackCirclePath.stroke()
            let rect = CGRect(x: center.x - (radius * 0.6/2), y: center.y - (radius * 0.6/2), width: radius * 0.6, height: radius * 0.6)
            let rectPath = UIBezierPath(roundedRect: rect, cornerRadius: 3)
            rectPath.close()
            rectPath.fill()
        }
    }
}
