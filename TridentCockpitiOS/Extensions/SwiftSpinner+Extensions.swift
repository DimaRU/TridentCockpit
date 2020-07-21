/////
////  SwiftSpinner+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

extension SwiftSpinner {
    class func addCircularProgress(to view: UIView, title: String, verticalSizeClass: UIUserInterfaceSizeClass) -> SwiftSpinner {
        let width = verticalSizeClass == .compact ? 170 : 200
        let spinner = SwiftSpinner(frame: CGRect(x: 0, y: 0, width: width, height: width))
        spinner.showBlurBackground = false
        spinner.titleLabel.textColor = .black
        let fontSize: CGFloat = verticalSizeClass == .compact ? 17 : 22
        let font = UIFont.systemFont(ofSize: fontSize)
        spinner.setTitleFont(font)
        spinner.outerColor = .systemTeal
        spinner.innerColor = .lightGray
        spinner.show(in: view, title: title)
        return spinner
     }
}
