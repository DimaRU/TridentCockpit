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
        guard let window = window else { return }
        let titlebarHeight = window.titlebarHeight
        mousePosRelatedToView = NSEvent.mouseLocation
        mousePosRelatedToView!.x -= frame.origin.x
        mousePosRelatedToView!.y -= frame.origin.y
        isAlignFeedbackSent = abs(frame.origin.y - (window.frame.height - frame.height - titlebarHeight) / 2) <= alignConst
        isDragging = true
    }

    func mouseDraggedAct(with event: NSEvent) {
        if (!isDragging) { return }
        guard let mousePos = mousePosRelatedToView, let windowFrame = window?.frame else { return }
        let titlebarHeight = window!.titlebarHeight
        let currentLocation = NSEvent.mouseLocation
        var newOrigin = CGPoint(
            x: currentLocation.x - mousePos.x,
            y: currentLocation.y - mousePos.y
        )
        // stick to center
        let yPosWhenCenter = (windowFrame.height - frame.height - titlebarHeight) / 2
        if abs(newOrigin.y - yPosWhenCenter) <= alignConst {
            newOrigin.y = yPosWhenCenter
            if !isAlignFeedbackSent {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                isAlignFeedbackSent = true
            }
        } else {
            isAlignFeedbackSent = false
        }
        // bound to window frame
        let xMax = windowFrame.width - frame.width
        let yMax = windowFrame.height - frame.height - titlebarHeight
        newOrigin = newOrigin.constrained(to: NSRect(x: 0, y: 0, width: xMax, height: yMax))
        // apply position
        xConstraint?.constant = newOrigin.x + frame.width / 2
        yConstraint?.constant = newOrigin.y + frame.height / 2
    }

    func mouseUpAct(with event: NSEvent) {
        isDragging = false
        guard let windowFrame = window?.frame else { return }
        //         save final position
        cph = (xConstraint?.constant ?? 0) / windowFrame.width
        cpv = (yConstraint?.constant ?? 0) / windowFrame.height
        savePosition(cph: cph, cpv: cpv)
    }

    func windowDidResize() {
        // update control bar position
        guard let window = window else { return }
        let windowWidth = window.frame.width
        let oscHalfWidth: CGFloat = frame.width / 2

        var xPos = windowWidth * CGFloat(cph)
        if xPos < oscHalfWidth {
            xPos = oscHalfWidth
        } else if xPos + oscHalfWidth > windowWidth {
            xPos = windowWidth - oscHalfWidth
        }

        let windowHeight = window.frame.height
        let oscHalHeight = frame.height / 2

        var yPos = windowHeight * CGFloat(cpv)
        if yPos < oscHalHeight {
            yPos = oscHalHeight
        } else if yPos + oscHalHeight > windowHeight {
            yPos = windowHeight - oscHalHeight
        }

        xConstraint?.constant = xPos
        yConstraint?.constant = yPos
    }

}
