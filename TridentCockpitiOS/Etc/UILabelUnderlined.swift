/////
////  UILabelUnderlined.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

@IBDesignable
class UILabelUnderlined: UILabel {

    override func awakeFromNib() {
        super.awakeFromNib()
        let temp = text
        text = temp
    }
    
override var text: String? {
    didSet {
        guard let text = text else {
            self.attributedText = nil
            return
        }
        let textRange = NSMakeRange(0, text.count)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(.underlineStyle , value: NSUnderlineStyle.single.rawValue, range: textRange)
        self.attributedText = attributedText
        }
    }
}
