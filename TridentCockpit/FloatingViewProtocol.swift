/////
////  FloatingViewProtocol.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

protocol FloatingViewProtocol: NSView {
    var xConstraint: NSLayoutConstraint? { get set }
    var yConstraint: NSLayoutConstraint? { get set }

    var mousePosRelatedToView: CGPoint? { get set }
    var isDragging: Bool { get set }
    var cpv: CGFloat { get set }
    var cph: CGFloat { get set }
    var alignConst: CGFloat { get }
    var isAlignFeedbackSent: Bool { get set }
    
    func savePosition(cph: CGFloat, cpv: CGFloat)
    func loadPosition() -> (cph: CGFloat?, cpv: CGFloat?)
}

extension FloatingViewProtocol {
    func addConstraints() {
        assert(superview != nil)
        guard xConstraint == nil else { return }
        guard let superview = superview else { return }
        let (defcph, defcpv) = loadPosition()
        let x, y: CGFloat
        if defcph != nil, defcpv != nil {
            cph = defcph!
            cpv = defcpv!
            x = cph * superview.frame.width
            y = cpv * superview.frame.height
        } else {
            x = frame.midX
            y = frame.midY
            cph = x / superview.frame.width
            cpv = y / superview.frame.height
        }
        xConstraint = self.centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: x)
        yConstraint = superview.bottomAnchor.constraint(equalTo: self.centerYAnchor, constant: y)
        NSLayoutConstraint.activate([xConstraint!, yConstraint!])
    }
    
    func mouseDownAct(with event: NSEvent) {
        assert(superview != nil)
        mousePosRelatedToView = NSEvent.mouseLocation
        mousePosRelatedToView!.x -= frame.origin.x
        mousePosRelatedToView!.y -= frame.origin.y
        isAlignFeedbackSent = abs(frame.origin.y - (superview!.frame.height - frame.height) / 2) <= alignConst
        isDragging = true
    }

    func mouseDraggedAct(with event: NSEvent) {
        assert(superview != nil)
        if (!isDragging) { return }
        guard let mousePos = mousePosRelatedToView, let superFrame = superview?.frame else { return }
        let currentLocation = NSEvent.mouseLocation
        var newOrigin = CGPoint(
            x: currentLocation.x - mousePos.x,
            y: currentLocation.y - mousePos.y
        )
        // stick to center
        let yPosWhenCenter = (superFrame.height - frame.height) / 2
        if abs(newOrigin.y - yPosWhenCenter) <= alignConst {
            newOrigin.y = yPosWhenCenter
            if !isAlignFeedbackSent {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                isAlignFeedbackSent = true
            }
        } else {
            isAlignFeedbackSent = false
        }
        // bound to superview frame
        let xMax = superFrame.width - frame.width
        let yMax = superFrame.height - frame.height
        newOrigin = newOrigin.constrained(to: NSRect(x: 0, y: 0, width: xMax, height: yMax))
        // apply position
        xConstraint?.constant = newOrigin.x + frame.width / 2
        yConstraint?.constant = newOrigin.y + frame.height / 2
    }

    func mouseUpAct(with event: NSEvent) {
        assert(superview != nil)
        isDragging = false
        //         save final position
        cph = (xConstraint?.constant ?? 0) / superview!.frame.width
        cpv = (yConstraint?.constant ?? 0) / superview!.frame.height
        savePosition(cph: cph, cpv: cpv)
    }

    func superViewDidResize() {
        assert(superview != nil)
// update control bar position
        let oscHalfWidth: CGFloat = frame.width / 2

        var xPos = superview!.frame.width * CGFloat(cph)
        if xPos < oscHalfWidth {
            xPos = oscHalfWidth
        } else if xPos + oscHalfWidth > superview!.frame.width {
            xPos = superview!.frame.width - oscHalfWidth
        }

        let oscHalHeight = frame.height / 2
        var yPos = superview!.frame.height * CGFloat(cpv)
        if yPos < oscHalHeight {
            yPos = oscHalHeight
        } else if yPos + oscHalHeight > superview!.frame.height {
            yPos = superview!.frame.height - oscHalHeight
        }

        xConstraint?.constant = xPos
        yConstraint?.constant = yPos
    }

}
