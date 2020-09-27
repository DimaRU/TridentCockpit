/////
////  WindowController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = "TridentVideoWindow"
        self.window?.contentAspectRatio = NSSize(width: 16, height: 9)
    }

    func windowWillClose(_ notification: Notification) {
        FastRTPS.removeParticipant()
        DisplayManager.enableSleep()
    }

}

