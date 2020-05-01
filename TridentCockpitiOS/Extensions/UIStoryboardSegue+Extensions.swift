/////
////  UIStoryboardSegue+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

// Thanks https://stackoverflow.com/a/37602422/7666732

class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?

    override func perform() {
        super.perform()
        completion?()
    }
}
