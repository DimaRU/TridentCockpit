/////
////  VideoView.swift
///   Copyright © 2010 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import AVFoundation

class VideoView: UIView {
    var sampleBufferLayer: AVSampleBufferDisplayLayer {
        layer.sublayers!.first as! AVSampleBufferDisplayLayer
    }
    

    override init(frame: CGRect) {
        super.init(frame: frame)
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

        layer.addSublayer(sampleBufferLayer)
    }
}
