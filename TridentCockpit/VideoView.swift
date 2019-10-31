/////
////  VideoView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVFoundation

class VideoView: NSView {
    var sampleBufferLayer = AVSampleBufferDisplayLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupVideoLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupVideoLayer()
    }

    func setupVideoLayer() {
        sampleBufferLayer.frame = bounds
        sampleBufferLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        sampleBufferLayer.isOpaque = true
        
        wantsLayer = true
        layer?.contents = NSImage(named: "Trident")
        layer?.addSublayer(self.sampleBufferLayer)
    }


    override func layout() {
        super.layout()
        sampleBufferLayer.frame = bounds
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        sampleBufferLayer.frame = bounds
    }
}
