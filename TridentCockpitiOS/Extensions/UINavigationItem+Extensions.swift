/////
////  UINavigationItem+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

extension UINavigationItem {
    enum Identifier: Int {
        case connectWiFi = 1
        case connectCamera = 2
    }

    func getLeftItem(for identifier: UINavigationItem.Identifier) -> UIBarButtonItem? {
        leftBarButtonItems?.first(where: { $0.tag == identifier.rawValue })
    }

    func getRightItem(for identifier: UINavigationItem.Identifier) -> UIBarButtonItem? {
        rightBarButtonItems?.first(where: { $0.tag == identifier.rawValue })
    }

    func getItem(for identifier: UINavigationItem.Identifier) -> UIBarButtonItem? {
        getLeftItem(for: identifier) ?? getRightItem(for: identifier)
    }
}
