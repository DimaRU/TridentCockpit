/////
////  UIBarButtonItem+Extension.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

extension UIBarButtonItem {
    var view: UIView? {
        guard let view = self.value(forKey: "view") as? UIView else {
            return nil
        }
        return view
    }
}
