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
        logView.text = errorLog
    }
    
    @IBAction func dismissButtonTap(_ sender: Any) {
        dismiss(animated: true)
    }
    
    
}
