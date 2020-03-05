/////
////  CameraControlView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit

class CameraControlView: FloatingView {

    override func awakeFromNib() {
        super.awakeFromNib()
        cornerRadius = 6
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "cameraControlBackground")!
    }

    override func loadDefaults() -> CGPoint {
        assert(superview != nil)
        let cph = (superview!.frame.minX + bounds.midX) / superview!.frame.width
        let cpv = (superview!.frame.midY) / superview!.frame.height
        return CGPoint(x: cph, y: cpv)
    }

    override func savePosition(cp: CGPoint) {
        Preference.cameraControlViewCPH = cp.x
        Preference.cameraControlViewCPV = cp.y
    }

    override func loadPosition() -> CGPoint? {
        guard let cph = Preference.cameraControlViewCPH,
            let cpv = Preference.cameraControlViewCPV else { return nil }
        return CGPoint(x: cph, y: cpv)
    }

}
