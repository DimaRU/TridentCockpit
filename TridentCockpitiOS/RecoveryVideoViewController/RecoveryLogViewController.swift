/////
////  RecoveryLogViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

class RecoveryLogViewController: UIViewController {
    @IBOutlet weak var logView: UITextView!
    var errorLog = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        logView.text = errorLog
    }
    
    @IBAction func dismissButtonTap(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

extension RecoveryLogViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}
