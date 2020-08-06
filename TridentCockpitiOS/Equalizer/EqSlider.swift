/////
////  EqSlider.swift
///  Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

@IBDesignable
class EqSlider: UISlider {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSlider()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSlider()
    }
    
    #if TARGET_INTERFACE_BUILDER
    override func prepareForInterfaceBuilder() {
        setupSlider()
    }
    #endif
    
    private func setupSlider() {
        let bundle = Bundle.init(for: Self.self)
        let trackImage = UIImage(named: "track", in: bundle, with: nil)
        setMinimumTrackImage(trackImage, for: .normal)
        setMaximumTrackImage(trackImage, for: .normal)
        let thumbImage = UIImage(named: "thumb", in: bundle, with: nil)
        setThumbImage(thumbImage, for: .normal)
        setThumbImage(thumbImage, for: .highlighted)
    }
}
