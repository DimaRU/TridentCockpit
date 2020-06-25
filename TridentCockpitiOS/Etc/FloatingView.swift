/////
////  FloatingView.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

class FloatingView: UIView {

    private var xConstraint: NSLayoutConstraint?
    private var yConstraint: NSLayoutConstraint?

    var alignConst: CGFloat { 10 }
    var offsetFromTop: CGFloat = 0
    private var viewCenter: CGPoint!
    private var isAlignFeedbackSent = false

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil, let superview = superview else { return }
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(recognizer:)))
        self.addGestureRecognizer(recognizer)
        borderColor = .gray

        let cp = loadPosition() ?? loadDefaults()
        let x = cp.x * superview.frame.width
        let y = cp.y * superview.frame.height

        xConstraint = centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: x)
        yConstraint = centerYAnchor.constraint(equalTo: superview.topAnchor, constant: y)
        NSLayoutConstraint.activate([xConstraint!, yConstraint!])
    }

    @objc func panGestureHandler(recognizer: UIPanGestureRecognizer) {
        assert(superview != nil)
        let view = recognizer.view!

        switch recognizer.state {
        case .began:
            viewCenter = view.center
            isAlignFeedbackSent = abs(frame.origin.y - (superview!.frame.height - frame.height) / 2) <= alignConst
            view.borderWidth = 3

        case .changed:
            let superFrame = superview!.frame
            let translation = recognizer.translation(in: view.superview!)
            var newOrigin = CGPoint(x: viewCenter!.x + translation.x, y: viewCenter!.y + translation.y)

            // stick to center
            let yPosWhenCenter = superFrame.height / 2
            if abs(newOrigin.y - yPosWhenCenter) <= alignConst {
                newOrigin.y = yPosWhenCenter
                if !isAlignFeedbackSent {
                    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
                    impactFeedbackgenerator.prepare()
                    impactFeedbackgenerator.impactOccurred()
                    isAlignFeedbackSent = true
                }
            } else {
                isAlignFeedbackSent = false
            }
            // bound to superview frame
            let xMax = superFrame.width - frame.width
            let yMax = superFrame.height - frame.height
            newOrigin = newOrigin.constrained(to: CGRect(x: frame.width / 2, y: frame.height / 2, width: xMax, height: yMax))

            xConstraint?.constant = newOrigin.x
            yConstraint?.constant = newOrigin.y
        case .ended, .cancelled:
            viewCenter = view.center
            view.borderWidth = 0
            let cph = viewCenter.x / superview!.frame.width
            let cpv = viewCenter.y / superview!.frame.height
            savePosition(cp: CGPoint(x: cph, y: cpv))
        default:
            break
        }
    }

    func loadDefaults() -> CGPoint {
        CGPoint(x: 0, y: 0)
    }

    func savePosition(cp: CGPoint) {}

    func loadPosition() -> CGPoint? {
        nil
    }

    func superViewDidResize(to size: CGSize) {
        assert(superview != nil)
        let cph = center.x / superview!.frame.width
        let cpv = center.y / superview!.frame.height

        xConstraint?.constant = cph * size.width
        yConstraint?.constant = cpv * size.height
    }
}
