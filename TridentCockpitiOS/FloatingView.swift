/////
////  FloatingView.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

class FloatingView: UIView {

    let alignConst: CGFloat = 10
    private var viewCenter: CGPoint!
    private var isAlignFeedbackSent = false
    private var cpv: CGFloat = 0
    private var cph: CGFloat = 0

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(recognizer:)))
        self.addGestureRecognizer(recognizer)
        borderColor = .gray

        let (defcph, defcpv) = loadPosition()
        if defcph != nil, defcpv != nil {
            cph = defcph!
            cpv = defcpv!
        } else {
            (cph, cpv) = loadDefaults()
        }
        center = CGPoint(x: cph * superview!.frame.width, y: cpv * superview!.frame.height)
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
            view.center = newOrigin
        case .ended, .cancelled:
            viewCenter = view.center
            view.borderWidth = 0
            cph = viewCenter.x / superview!.frame.width
            cpv = viewCenter.y / superview!.frame.height
            savePosition(cph: cph, cpv: cpv)
        default:
            break
        }
    }
   
    func loadDefaults() -> (cph: CGFloat, cpv: CGFloat) {
        return (0, 0)
    }

    func savePosition(cph: CGFloat, cpv: CGFloat) {
    }
    
    func loadPosition() -> (cph: CGFloat?, cpv: CGFloat?) {
        return (0, 0)
    }
}
