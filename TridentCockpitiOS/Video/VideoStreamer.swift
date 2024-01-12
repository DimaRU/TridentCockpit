/////
////  VideoStreamer.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

protocol VideoStreamerDelegate: AnyObject {
    func state(published: Bool)
    func stats(fps: UInt16, bytesOutPerSecond: Int32, totalBytesOut: Int64)
    func showError(_ error: StreamerError)
}

enum StreamerError: Error {
    case publishingError
    case connectionError
}
extension StreamerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .publishingError: return "Publishing error"
        case .connectionError: return "Connection error"
        }
    }
}

class VideoStreamer: NSObject, VideoProcessorDelegate {
    enum State {
        case disconnected, connected, publishing, published
    }
    weak var delegate: VideoStreamerDelegate?
    var isPublished: Bool { state == .published }
    
    private var streamKey: String
    private var streamURL: String
    private var retryCount: Int = 0
    private var observation: NSKeyValueObservation?
    
    private var state: State {
        didSet {
            guard state != oldValue else { return }
            delegate?.state(published: isPublished)
        }
    }
    
    private lazy var rtmpConnection: RTMPConnection = {
        let connection = RTMPConnection()
        connection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
        connection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        //        connection.requireNetworkFramework = true
        return connection
    }()
    
    @objc
    private lazy var rtmpStream: RTMPStream = {
        RTMPStream(connection: rtmpConnection)
    }()
    
    init(url: String, key: String) {
        streamKey = key
        streamURL = url
        state = .disconnected
        super.init()
    }
    
    deinit {
        print(#file, #line, #function)
        observation?.invalidate()
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
        rtmpStream.close()
        rtmpStream.dispose()
    }
    
    func cleanup() {
        disconnect()
        rtmpStream.close()
        rtmpStream.dispose()
    }
    
    func connect() {
        rtmpConnection.connect(streamURL)
        observation = observe(\.rtmpStream.currentFPS, options: .new) { [weak self] (object, change) in
            guard let self = self else { return }
            self.delegate?.stats(fps: self.rtmpStream.currentFPS,
                                 bytesOutPerSecond: self.rtmpConnection.currentBytesOutPerSecond,
                                 totalBytesOut: self.rtmpConnection.totalBytesOut)
        }
        rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print(error)
        }
        print(AVCaptureDevice.default(for: .audio)?.description ?? "no audio")
    }
    
    func disconnect() {
        state = .disconnected
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
        let e = Event.from(notification)
        print("Error:", e)
        delegate?.showError(.connectionError)
        state = .disconnected
        rtmpConnection.connect(streamURL)
    }
    
    @objc
    private func rtmpStatusEvent(_ notification: Notification) {
        let e = Event.from(notification)
        guard
            let data: ASObject = e.data as? ASObject,
            let code: String = data["code"] as? String else {
                print("---- No code event:", e)
                return
        }
        print("rtmp status:", code)
        switch code {
        case RTMPConnection.Code.connectFailed.rawValue:
            state = .disconnected
            rtmpConnection.close()
            delegate?.showError(.connectionError)
        case RTMPConnection.Code.connectRejected.rawValue:
            state = .disconnected
            delegate?.showError(.connectionError)
            break
        case RTMPConnection.Code.connectSuccess.rawValue:
            retryCount = 0
            rtmpStream.publish(streamKey)
            state = .publishing
        case RTMPStream.Code.publishFailed.rawValue:
            state = .disconnected
            disconnect()
            delegate?.showError(.publishingError)
        case RTMPStream.Code.unpublishSuccess.rawValue:
            disconnect()
            state = .disconnected
        case RTMPStream.Code.publishStart.rawValue:
            state = .published
        case "NetStream.Unpublish.InternalKill":
            // Freezed stream, must reconnect/republish
            state = .connected
        case RTMPConnection.Code.connectClosed.rawValue:
            guard state != .publishing else {
                state = .disconnected
                // Wrong publishing
                delegate?.showError(.publishingError)
                return
            }
            guard state != .disconnected else {
                return
            }
            fallthrough
        case RTMPConnection.Code.connectFailed.rawValue:
            state = .disconnected
            guard retryCount < 5 else {
                delegate?.showError(.connectionError)
                break
            }
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5) {
                self.rtmpConnection.connect(self.streamURL)
            }
        default:
            print("---- Unknown event", e)
            break
        }
    }
}
