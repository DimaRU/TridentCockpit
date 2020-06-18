/////
////  VideoStreamer.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
//import HaishinKit
import AVFoundation
import VideoToolbox

protocol VideoStreamerDelegate: class {
    func state(connected: Bool)
}

class VideoStreamer: VideoProcessorDelegate {
    private var streamName: String
    private var streamURL: String
    private var sentFormat = false
    private var retryCount: Int = 0
    weak var delegate: VideoStreamerDelegate?

    private lazy var rtmpConnection: RTMPConnection = {
        let connection = RTMPConnection()
        connection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
        connection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        return connection
    }()
    
    private lazy var rtmpStream: RTMPStream = {
        RTMPStream(connection: rtmpConnection)
    }()
    
    init(url: String, name: String) {
        streamName = name
        streamURL = url
    }
    
    deinit {
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
        rtmpStream.close()
        rtmpStream.dispose()
    }
    
    func cleanup() {
    }

    func connect() {
        rtmpConnection.connect(streamURL, arguments: nil)
    }
    
    func disconnect() {
        rtmpConnection.close()
        delegate?.state(connected: false)
    }
    
    func pause() {
        rtmpStream.paused = true
    }
    
    func resume() {
        rtmpStream.paused = false
    }
    
    func setVideoFormat(width: Int, height: Int, bitrate: Int) {
        rtmpStream.videoSettings = [
            .width: width,
            .height: height,
            .bitrate: bitrate,
            .profileLevel: kVTProfileLevel_H264_Baseline_AutoLevel
        ]

        rtmpStream.audioSettings = [.bitrate: 32000]
    }
    
    private func createMetaData() -> ASObject {
        var metadata = ASObject()
        metadata["width"] = 1280
        metadata["height"] = 720
        metadata["framerate"] = 30
        metadata["videocodecid"] = FLVVideoCodec.avc.rawValue
        metadata["videodatarate"] = 1500000 / 1000
        if AVCaptureDevice.default(for: .audio) != nil {
            metadata["audiocodecid"] = FLVAudioCodec.aac.rawValue
            metadata["audiodatarate"] = rtmpStream.mixer.audioIO.encoder.bitrate / 1000
        }
        return metadata
    }
    
    func set(format: CMVideoFormatDescription, time: CMTime) {
        guard !sentFormat else { return }

        rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print(error)
        }
        print(AVCaptureDevice.default(for: .audio)?.description ?? "no audio")
        rtmpStream.mixer.videoIO.formatDescription = format
        rtmpStream.metadata(createMetaData())
        rtmpStream.muxer.didSetFormatDescription(video: format)
        sentFormat = true
    }
    
    func processNal(sampleBuffer: CMSampleBuffer) {
        guard sentFormat else { return }
        rtmpStream.muxer.sampleOutput(video: sampleBuffer)
    }
    
    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        rtmpConnection.connect(streamURL)
    }
    
    @objc
    private func rtmpStatusEvent(_ notification: Notification) {
        let e = Event.from(notification)
        guard
            let data: ASObject = e.data as? ASObject,
            let code: String = data["code"] as? String else {
                return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            retryCount = 0
            rtmpStream.publish(streamName)
        case RTMPStream.Code.publishStart.rawValue:
            delegate?.state(connected: true)
            print("Publish start")
        case RTMPConnection.Code.connectFailed.rawValue,
             RTMPConnection.Code.connectClosed.rawValue:
            
            delegate?.state(connected: false)
            guard retryCount < 5 else {
                return
            }
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
                self.connect()
            }
        default:
            print(e)
            break
        }
    }
}
