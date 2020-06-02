/////
////  VideoWriter.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation

class VideoWriter {
    let writer: AVAssetWriter
    var videoInput: AVAssetWriterInput!
    var sessionStarted = false
    
    init(path: String, location: CLLocation?) throws {
        let url = RecordingsAPI.moviesURL.appendingPathComponent("Pilot").appendingPathComponent(path + ".mp4")
        try? FileManager.default.removeItem(at: url)
        writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        
        guard let location = location else { return }
        let gpsMetadata = AVMutableMetadataItem()
        gpsMetadata.identifier = AVMetadataIdentifier.quickTimeMetadataLocationISO6709
        gpsMetadata.value = location.iso6709String as NSString
        writer.metadata = [gpsMetadata]
        print(writer.metadata)
    }
        
    func startSession(at sourceTime: CMTime, format: CMFormatDescription) {
        guard !sessionStarted else { return }
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: format)
        videoInput.expectsMediaDataInRealTime = true
//        assert(writer.canAdd(videoInput))
        
        writer.add(videoInput)
        writer.startWriting()
        writer.startSession(atSourceTime: sourceTime)
        sessionStarted = true
    }
    
    func addVideoData(sampleBuffer: CMSampleBuffer) {
        guard sessionStarted else { return }
        guard writer.status != .failed else {
            writer.cancelWriting()
            if let error = writer.error {
                print(error)
            }
            return
        }

        guard videoInput.isReadyForMoreMediaData else {
            assert(true, "Not ready for data")
            return
        }
        videoInput.append(sampleBuffer)
    }
    
    func finishSession(completion: @escaping () -> Void) {
        guard sessionStarted else { return }
        writer.finishWriting(completionHandler: completion)
    }
}
