/////
////  PastDivesViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

class PastDivesViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func closeButtonPress(_ sender: Any) {
        FastRTPS.resignAll()
        guard let otherViewController = self.parent?.children.first(where: { $0 != self}) else { return }
        self.parent!.transition(from: self, to: otherViewController, options: .slideDown) {
            self.removeFromParent()
        }
    }
}
