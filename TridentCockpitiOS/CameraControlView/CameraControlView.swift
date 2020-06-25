/////
////  CameraControlView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import FastRTPSBridge
import CoreLocation

class CameraControlView: FloatingView {
    @IBOutlet weak var recordingButton: CameraButton!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var remainingOnboardLabel: UILabel!
    @IBOutlet weak var remainingLocalLabel: UILabel!
    @IBOutlet weak var onboardLabel: UILabel!
    @IBOutlet weak var iPhoneLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    private var videoSessionId: UUID?
    private var timer: Timer?
    private var videoRecorder: VideoRecorder?
    private weak var videoProcessorMulticastDelegate: VideoProcessorMulticastDelegate?
    var currentLocation: CLLocation?
    
    private var recordingTime: Int? {
        didSet {
            guard let time = recordingTime else {
                recordingTimeLabel.text = nil
                return
            }
            let sec = time % 60
            let min = time / 60
            let hour = time / 3600
            recordingTimeLabel.text = String(format: "%2.2d:%2.2d:%2.2d", hour, min, sec)
            if sec == 0 {
                refreshLocalRemainingTime()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        cornerRadius = 6
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "cameraControlBackground")!
        
        #if targetEnvironment(macCatalyst)
        iPhoneLabel.text = "mac:"
        #else
        iPhoneLabel.text = UIDevice.current.model + ":"
        #endif
        if !Preference.recordOnboardVideo {
            onboardLabel.isHidden = true
            remainingOnboardLabel.isHidden = true
        }
        if !Preference.recordPilotVideo {
            iPhoneLabel.isHidden = true
            remainingLocalLabel.isHidden = true
        }
        
        remainingOnboardLabel.text = " "
        remainingLocalLabel.text = " "
        
        setViewState(recording: false)
    }

    override func loadDefaults() -> CGPoint {
        assert(superview != nil)
        let cph = (superview!.frame.minX + bounds.midX) / superview!.frame.width
        let cpv = (superview!.frame.midY) / superview!.frame.height
        return CGPoint(x: cph, y: cpv)
    }

    override func savePosition(cp: CGPoint) {
        Preference.cameraControlViewCPH = cp.x
        Preference.cameraControlViewCPV = cp.y
    }

    override func loadPosition() -> CGPoint? {
        guard let cph = Preference.cameraControlViewCPH,
            let cpv = Preference.cameraControlViewCPV else { return nil }
        return CGPoint(x: cph, y: cpv)
    }

    @IBAction func recordingButtonPress(_ sender: Any) {
        switchRecording()
    }

    private func remainingTime(from minutes: Int) -> String {
        var time = ""
        if minutes / 60 != 0 {
            #if targetEnvironment(simulator)
            let hours = (minutes / 60) % 100
            time += String(hours) + "h "
            #else
            time += String(minutes / 60) + "h "
            #endif
        }
        time += String(minutes % 60) + "m"
        return time
    }
    
    private func setViewState(recording: Bool) {
        let labelList = [
            remainingOnboardLabel,
            remainingLocalLabel,
            onboardLabel,
            iPhoneLabel,
            remainingTimeLabel,
        ]

        if recording {
            recordingTime = 0
            recordingButton.isSelected = true
            labelList.forEach{ $0?.textColor = .white }
            
        } else {
            recordingTime = nil
            recordingButton.isSelected = false
            labelList.forEach{ $0?.textColor = .lightGray }
        }
    }
    
    private func registerReaders() {
        
        FastRTPS.registerReader(topic: .rovRecordingStats) { [weak self] (recordingStats: RovRecordingStats) in
            guard let self = self else { return }
            let minutes = Int(recordingStats.estRemainingRecTimeS) / 60
            DispatchQueue.main.async {
                self.remainingOnboardLabel.text = self.remainingTime(from: minutes)
                guard minutes == 0 else { return }
                if !self.recordingButton.isSelected {
                    self.recordingButton.isEnabled = false
                }
            }
        }
        
        FastRTPS.registerReader(topic: .rovVidSessionCurrent) { [weak self] (videoSession: RovVideoSession) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch videoSession.state {
                case .unknown:
                    break
                case .recording:
                    if self.videoSessionId == nil {
                        self.videoSessionId = UUID(uuidString: videoSession.sessionID)
                    }
                    if !self.recordingButton.isSelected {
                        self.setViewState(recording: true)
                    }
                    self.recordingTime = Int(videoSession.totalDurationS)

                case .stopped:
                    self.videoSessionId = nil
                    switch videoSession.stopReason {
                    case .maxSessionSizeReached:
                        self.startRecordingSession()
                        return
                    case .clientRequest,
                         .clientNotAlive,
                         .videoSourceNotAlive:
                        break
                    case .unknown:
                        break
                    case .filesystemNospace:
                        alert(message: "Stop recording", informative: "No space left", delay: 6)
                        break
                    case .recordingError:
                        alert(message: "Stop recording", informative: "Recording error", delay: 6)
                        break
                    }
                    self.setViewState(recording: false)
                }
            }
        }

        FastRTPS.registerReader(topic: .rovVidSessionRep) { [weak self] (videoSessionCommand: RovVideoSessionCommand) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch videoSessionCommand.response {
                case .unknown:
                    break
                case .accepted:
                    self.videoSessionId = UUID(uuidString: videoSessionCommand.sessionID)
                case .rejectedGeneric:
                    self.videoSessionId = nil
                case .rejectedInvalidSession:
                    self.videoSessionId = nil
                case .rejectedSessionInProgress:
                    self.videoSessionId = nil
                    alert(message: "Recording", informative: "Already in progress")
                case .rejectedNoSpace:
                    self.videoSessionId = nil
                    alert(message: "Recording", informative: "No space left")
                }
            }
        }
        

    }
    
    private func startRecordingSession() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoDate = formatter.string(from: Date())
        
        if Preference.recordOnboardVideo, videoSessionId == nil {
            let id = UUID()
            let metadata = #"{"start_ts":"\#(isoDate)"}"#
            let videoSessionCommand = RovVideoSessionCommand(sessionID: id.uuidString.lowercased(),
                                                             metadata: metadata,
                                                             request: .recording,
                                                             response: .unknown,
                                                             reason: "")
            FastRTPS.send(topic: .rovVidSessionReq, ddsData: videoSessionCommand)
        }

        guard Preference.recordPilotVideo, videoRecorder == nil else { return }
        if let videoRecorder = try? VideoRecorder(startDate: isoDate, location: currentLocation) {
            self.videoRecorder = videoRecorder
            videoProcessorMulticastDelegate?.add(videoRecorder)
        }

        guard !Preference.recordOnboardVideo else { return }
        setViewState(recording: true)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.recordingTime? += 1
        }
    }
    
    private func stopRecordingSession() {
        if Preference.recordOnboardVideo, let videoSessionId = videoSessionId {
            let videoSessionCommand = RovVideoSessionCommand(sessionID: videoSessionId.uuidString.lowercased(),
                                                             metadata: "",
                                                             request: .stopped,
                                                             response: .unknown,
                                                             reason: "")
            FastRTPS.send(topic: .rovVidSessionReq, ddsData: videoSessionCommand)
        }

        guard Preference.recordPilotVideo else { return }
        videoRecorder?.finishSession {
            self.videoProcessorMulticastDelegate?.remove(self.videoRecorder!)
            self.videoRecorder = nil
        }
        guard !Preference.recordOnboardVideo else { return }
        timer?.invalidate()
        timer = nil
        setViewState(recording: false)
    }

    func switchRecording() {
        if recordingButton.isSelected {
            stopRecordingSession()
        } else {
            startRecordingSession()
        }
    }
    
    func start() {
        registerReaders()
        refreshLocalRemainingTime()
    }
    
    private func refreshLocalRemainingTime() {
        let path = RecordingsAPI.moviesURL.path
        let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: path)
        let freeSpace = (systemAttributes?[FileAttributeKey.systemFreeSize] as? NSNumber)?.intValue ?? 0
        let remainingSeconds = freeSpace / 230_000
        let remainingMinutes = remainingSeconds / 60
        remainingLocalLabel.text = remainingTime(from: remainingMinutes)
    }
    
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Instaniate
    static func instantiate(_ videoProcessorMulticastDelegate: VideoProcessorMulticastDelegate) -> CameraControlView {
        let nib = UINib(nibName: "CameraControlView", bundle: nil)
        let views = nib.instantiate(withOwner: CameraControlView(), options: nil)
        let view = views.first as! CameraControlView
        view.videoProcessorMulticastDelegate = videoProcessorMulticastDelegate
        return view
    }
}
