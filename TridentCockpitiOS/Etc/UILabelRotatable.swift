/////
////  UILabelRotatable.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

@IBDesignable
class UILabelRotatable: UILabel {
    @IBInspectable
    var rotation: Int {
        get {
            return 0
        } set {
            let radians = CGFloat(Double(newValue) * .pi / 180.0)
            self.transform = CGAffineTransform(rotationAngle: radians)
        }
    }
}
