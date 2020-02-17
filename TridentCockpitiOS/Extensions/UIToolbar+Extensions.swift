/////
////  UIToolbar+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

extension UIToolbar {
    enum Identifier: Int {
        case connectWiFi = 1
        case connectCamera = 2
    }

    func getItem(for identifier: UIToolbar.Identifier) -> UIBarButtonItem? {
        return self.items?.first(where: { $0.tag == identifier.rawValue })
    }

}

