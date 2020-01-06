/////
////  WindowController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = "TridentVideoWindow"
    }

}

