//////
////   HeaderView.swift
///    Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class HeaderView: NSView {
    @IBOutlet weak var label: NSTextField!
 
    override func awakeFromNib() {
        super.awakeFromNib()

        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0, alpha: 0.1).cgColor
    }
    
}
