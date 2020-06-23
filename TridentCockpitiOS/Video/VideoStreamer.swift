/////
////  VideoStreamer.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

protocol VideoStreamerDelegate: class {
    func state(connected: Bool)
}

class VideoStreamer: VideoProcessorDelegate {
    private var streamKey: String
    private var streamURL: String
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
    
    init(url: String, key: String) {
        streamKey = key
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
        rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print(error)
        }
        print(AVCaptureDevice.default(for: .audio)?.description ?? "no audio")
    }
    
    func disconnect() {
        rtmpConnection.close()
    }
    
    func pause() {
        rtmpStream.paused = true
    }
    
    func resume() {
        rtmpStream.paused = false
    }
    
    func setVideoFormat() {
        rtmpStream.videoSettings = [
            .width: 1280,
            .height: 720,
            .bitrate: 1500000,
            .maxKeyFrameIntervalDuration: 3,
        ]

        rtmpStream.audioSettings = [.bitrate: 32000]
    }
        
    func set(format: CMVideoFormatDescription, time: CMTime) {
        rtmpStream.mixer.videoIO.formatDescription = format
        rtmpStream.muxer.didSetFormatDescription(video: format)
    }
    
    func processNal(sampleBuffer: CMSampleBuffer) {
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
            rtmpStream.publish(streamKey)
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
                self.rtmpConnection.connect(self.streamURL)
            }
        default:
            print(e)
            break
        }
    }
}
