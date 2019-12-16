/////
////  DashboardViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

class DashboardViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        print(self.className, #function)
        view.window?.toolbar?.isVisible = true
    }
    
    override func viewWillDisappear() {
        print(self.className, #function)
        view.window?.toolbar?.isVisible = false
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        print("segue:", segue.identifier!)
    }

}
