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

    func windowWillClose(_ notification: Notification) {
        FastRTPS.deleteParticipant()
        DisplayManager.enableSleep()
    }

}

