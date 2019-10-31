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
        var controlTimebase: CMTimebase?

        sampleBufferLayer.frame = bounds
        sampleBufferLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        sampleBufferLayer.isOpaque = true

        CMTimebaseCreateWithMasterClock(allocator: kCFAllocatorDefault,
                                        masterClock: CMClockGetHostTimeClock(),
                                        timebaseOut: &controlTimebase)
        if let controlTimebase = controlTimebase {
            sampleBufferLayer.controlTimebase = controlTimebase
            CMTimebaseSetTime(controlTimebase, time: .zero)
            CMTimebaseSetRate(controlTimebase, rate: 1.0)
        }

        sampleBufferLayer.contents = NSImage(named: "Trident")
        wantsLayer = true
        layer?.addSublayer(self.sampleBufferLayer)
        if #available(OSX 10.15, *) {
            sampleBufferLayer.preventsDisplaySleepDuringVideoPlayback = true
        }
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
