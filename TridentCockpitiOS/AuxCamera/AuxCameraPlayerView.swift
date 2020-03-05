/////
////  AuxCameraPlayerView.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

class AuxCameraPlayerView: FloatingView {
    override func loadDefaults() -> CGPoint {
        assert(superview != nil)
        let cph = (superview!.frame.midX - bounds.midX) / superview!.frame.width
        let cpv = (superview!.frame.maxY - bounds.midY) / superview!.frame.height
        return CGPoint(x: cph, y: cpv)
    }

    override func savePosition(cp: CGPoint) {
        Preference.auxCameraPlayerViewCPH = cp.x
        Preference.auxCameraPlayerViewCPV = cp.y
    }

    override func loadPosition() -> CGPoint? {
        guard let cph = Preference.auxCameraPlayerViewCPH,
              let cpv = Preference.auxCameraPlayerViewCPV else { return nil }
        return CGPoint(x: cph, y: cpv)
    }
}
