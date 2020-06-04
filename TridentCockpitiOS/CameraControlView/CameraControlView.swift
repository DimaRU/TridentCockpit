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
    @IBOutlet weak var remainingOnboardTimeLabel: UILabel!
    @IBOutlet weak var remainingiPhoneTimeLabel: UILabel!
    @IBOutlet weak var onboardLabel: UILabelUnderlined!
    @IBOutlet weak var iPhoneLabel: UILabelUnderlined!
    
    private var videoSessionId: UUID?
    private var timer: Timer?
    private weak var videoDecoder: VideoDecoder?
    var currentLocation: CLLocation?

    override func awakeFromNib() {
        super.awakeFromNib()
        cornerRadius = 6
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "cameraControlBackground")!
        
        iPhoneLabel.text = UIDevice.current.model + ":"
        if !Preference.recordOnboardVideo {
            onboardLabel.isHidden = true
            remainingOnboardTimeLabel.isHidden = true
        }
        if !Preference.recordPilotVideo && Preference.recordOnboardVideo {
            iPhoneLabel.isHidden = true
            remainingiPhoneTimeLabel.isHidden = true
        }
        
        remainingOnboardTimeLabel.text = " "
        remainingiPhoneTimeLabel.text = " "
        onboardLabel.textColor = .systemGray
        iPhoneLabel.textColor = .systemGray
        remainingOnboardTimeLabel.textColor = .systemGray
        remainingiPhoneTimeLabel.textColor = .systemGray

        recordingTimeLabel.text = ""
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
            time += String(minutes / 60) + "h "
        }
        time += String(minutes % 60) + "m"
        return time
    }
    
    private func registerReaders() {
        
        FastRTPS.registerReader(topic: .rovRecordingStats) { [weak self] (recordingStats: RovRecordingStats) in
            guard let self = self else { return }
            let minutes = Int(recordingStats.estRemainingRecTimeS) / 60
            DispatchQueue.main.async {
                self.remainingOnboardTimeLabel.text = self.remainingTime(from: minutes)
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
                    let sec = videoSession.totalDurationS % 60
                    let min = (videoSession.totalDurationS / 60)
                    let hour = videoSession.totalDurationS / 3600
                    self.recordingTimeLabel.text = String(format: "%2.2d:%2.2d:%2.2d", hour, min, sec)
                    
                    self.recordingButton.isSelected = true
                    self.remainingOnboardTimeLabel.textColor = .white

                case .stopped:
                    self.videoSessionId = nil
                    switch videoSession.stopReason {
                    case .maxSessionSizeReached:
                        self.startRecordingSession(id: UUID())
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
                    self.recordingTimeLabel.text = ""
                    self.remainingOnboardTimeLabel.textColor = .systemGray
                    self.recordingButton.isSelected = false
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
    
    private func startRecordingSession(id: UUID) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoDate = formatter.string(from: Date())
        let metadata = #"{"start_ts":"\#(isoDate)"}"#
        let videoSessionCommand = RovVideoSessionCommand(sessionID: id.uuidString.lowercased(),
                                                         metadata: metadata,
                                                         request: .recording,
                                                         response: .unknown,
                                                         reason: "")
        FastRTPS.send(topic: .rovVidSessionReq, ddsData: videoSessionCommand)

        guard Preference.recordPilotVideo else { return }
        let videoRecorder = try? VideoRecorder(startDate: isoDate, location: currentLocation)
        videoDecoder?.videoRecorder = videoRecorder
    }
    
    private func stopRecordingSession(id: UUID) {
        let videoSessionCommand = RovVideoSessionCommand(sessionID: id.uuidString.lowercased(),
                                                         metadata: "",
                                                         request: .stopped,
                                                         response: .unknown,
                                                         reason: "")
        FastRTPS.send(topic: .rovVidSessionReq, ddsData: videoSessionCommand)
        
        videoDecoder?.videoRecorder?.finishSession {
            self.videoDecoder?.videoRecorder = nil
        }
    }

    func switchRecording() {
        if let videoSessionId = videoSessionId {
            stopRecordingSession(id: videoSessionId)
        } else {
            startRecordingSession(id: UUID())
        }
    }
    
    func start() {
        registerReaders()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            // Refresh local remainingtime
        }
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Instaniate
    static func instantiate() -> CameraControlView {
        let nib = UINib(nibName: "CameraControlView", bundle: nil)
        let views = nib.instantiate(withOwner: CameraControlView(), options: nil)
        let view = views.first as! CameraControlView
        return view
    }
}
