/////
////  VideoView.swift
///   Copyright © 2010 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import AVFoundation

class VideoView: UIView {
    private let sampleBufferLayer = AVSampleBufferDisplayLayer()

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
    
    func setGravity(fill: Bool) {
        sampleBufferLayer.videoGravity = fill ? .resizeAspectFill : .resizeAspect
        // Hack: reset frame for videoGravity effect
        sampleBufferLayer.frame = .zero
        sampleBufferLayer.frame = layer.bounds
    }
    
    override func layoutSublayers(of layer: CALayer) {
        layer.sublayers?.forEach {
            $0.frame = layer.bounds
        }
    }

}

extension VideoView: VideoProcessorDelegate {
    func processNal(sampleBuffer: CMSampleBuffer) {
        if sampleBufferLayer.isReadyForMoreMediaData {
            sampleBufferLayer.enqueue(sampleBuffer)
        }
        if sampleBufferLayer.status == .failed {
            sampleBufferLayer.flush()
        }
    }
    
    func set(format: CMVideoFormatDescription, time: CMTime) {
        if let controlTimebase = sampleBufferLayer.controlTimebase {
            CMTimebaseSetTime(controlTimebase, time: time)
        }
    }
    
    func cleanup() {
        sampleBufferLayer.flush()
    }
}
