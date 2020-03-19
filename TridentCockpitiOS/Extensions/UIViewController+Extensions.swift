/////
////  UIViewControllerExtensions.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import Alamofire

extension UIViewController {
    func getInterfaceOrientation() -> UIInterfaceOrientation? {
        if #available(iOS 13, *) {
            return view.window?.windowScene?.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
}
