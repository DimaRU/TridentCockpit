/////
////  VideoView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVFoundation

class VideoView: NSView {
    var sampleBufferLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }
    
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
        let sampleBufferLayer = AVSampleBufferDisplayLayer()
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
        if #available(OSX 10.15, *) {
            sampleBufferLayer.preventsDisplaySleepDuringVideoPlayback = true
        }

        wantsLayer = true
        layer = sampleBufferLayer
    }
}
