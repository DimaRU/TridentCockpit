/////
////  DivePreviewItem.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

class DiveCollectionItem: NSCollectionViewItem {
    
    @IBOutlet weak var selectImage: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    
    var actionHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectImage.isHidden = true
        
        let gestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(clickReconized(_:)))
        gestureRecognizer.numberOfClicksRequired = 1
        gestureRecognizer.buttonMask = 1
        titleLabel.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func clickReconized(_ sender: Any) {
        actionHandler?()
    }
    
    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            selectImage.isHidden = !isSelected

            if isSelected {
                view.layer?.backgroundColor = NSColor.white.cgColor
            } else {
                view.layer?.backgroundColor = NSColor.clear.cgColor
            }

        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        if event.clickCount == 2 {
            actionHandler?()
        }
    }

}
