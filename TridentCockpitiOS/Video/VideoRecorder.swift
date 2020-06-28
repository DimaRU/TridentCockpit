/////
////  VideoRecorder.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation

class VideoRecorder: VideoProcessorDelegate {
    let writer: AVAssetWriter
    var videoInput: AVAssetWriterInput!
    var sessionStarted = false
    
    init(startDate: String, location: CLLocation?) throws {
        RecordingsAPI.setupRecodingsDirs()
        let startTimestamp = startDate.dateFromISO8601!
        let fileName = RecordingsAPI.pilotFileName(startTimestamp: startTimestamp)
        let url = RecordingsAPI.moviesURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        let fileType: AVFileType
        switch Preference.pilotVideoFileType {
        case "mov":
            fileType = .mov
        case "mp4":
            fileType = .mp4
        default:
            fatalError("Unsupported file type")
        }
        writer = try AVAssetWriter(outputURL: url, fileType: fileType)
        
        guard let location = location else { return }
        let gpsMetadata = AVMutableMetadataItem()
        gpsMetadata.identifier = AVMetadataIdentifier.quickTimeMetadataLocationISO6709
        gpsMetadata.value = location.iso6709String as NSString

        let dateMetadata = AVMutableMetadataItem()
        dateMetadata.identifier = AVMetadataIdentifier.quickTimeMetadataLocationDate
        dateMetadata.value = location.timestamp.iso8601 as NSString

        writer.metadata = [gpsMetadata, dateMetadata]
    }
        
    func set(format: CMVideoFormatDescription, time: CMTime) {
        guard !sessionStarted else { return }
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: format)
        videoInput.expectsMediaDataInRealTime = true
//        assert(writer.canAdd(videoInput))
        
        writer.add(videoInput)
        writer.startWriting()
        writer.startSession(atSourceTime: time)
        sessionStarted = true
    }
    
    func processNal(sampleBuffer: CMSampleBuffer) {
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
    
    func cleanup() {
        finishSession {}
    }
    
    func finishSession(completion: @escaping () -> Void) {
        guard sessionStarted else { return }
        sessionStarted = false
        writer.finishWriting(completionHandler: completion)
    }
}
