/////
////  AuxCameraControlView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import AVKit
import PromiseKit

class AuxCameraControlView: FloatingView {
    @IBOutlet weak var recordingButton: CameraButton!
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var cameraTimeLabel: UILabel!
    @IBOutlet weak var batteryStatusLabel: UILabel!
    @IBOutlet weak var liveVideoButton: UIButton!
    @IBOutlet weak var batteryImageView: UIImageView!
    weak var liveViewController: AVPlayerViewController!
    weak var liveViewContainer: FloatingView!
    
    
    weak var delegate: UIViewController?
    private var timer: Timer?
    private enum CameraControlViewState {
        case off
        case on
        case recording
    }
    
    private var cameraState: CameraControlViewState = .on {
        didSet {
            if oldValue != cameraState {
                setup(state: cameraState)
            }
        }
    }
    
    private var cameraTime: UInt32 = 0 {
        didSet {
            guard cameraTime != 65535 else { return }
            var time = "Remaining time:\n"
            if cameraTime / 60 != 0 {
                time += String(cameraTime / 60) + "h "
            }
            if cameraTime % 60 != 0 {
                time += String(cameraTime % 60) + "m"
            }
            self.cameraTimeLabel.text = time
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cornerRadius = 6
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "cameraControlBackground")!
    }

    override func loadDefaults() -> CGPoint {
        assert(superview != nil)
        let cph = (superview!.frame.minX + bounds.midX) / superview!.frame.width
        let cpv = (superview!.frame.maxY - bounds.midY ) / superview!.frame.height
        return CGPoint(x: cph, y: cpv)
    }

    override func savePosition(cp: CGPoint) {
        Preference.auxCameraControlViewCPH = cp.x
        Preference.auxCameraControlViewCPV = cp.y
    }

    override func loadPosition() -> CGPoint? {
        guard let cph = Preference.auxCameraControlViewCPH,
              let cpv = Preference.auxCameraControlViewCPV else { return nil }
        return CGPoint(x: cph, y: cpv)
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil

        stopLiveView()
    }
    
    #if DEBUG
    deinit {
        print(String(describing: self), #function)
    }
    #endif
    
    // MARK: Instaniate
    static func instantiate(liveViewContainer: FloatingView, liveViewController: AVPlayerViewController) -> AuxCameraControlView {
        let nib = UINib(nibName: "AuxCameraControlView", bundle: nil)
        let views = nib.instantiate(withOwner: AuxCameraControlView(), options: nil)
        let view = views.first as! AuxCameraControlView
        
        view.recordingTimeLabel.text = ""
        view.batteryStatusLabel.text = "n/a"
        view.cameraTimeLabel.text = ""
        view.liveViewContainer = liveViewContainer
        view.liveViewController = liveViewController
        liveViewContainer.isHidden = true

        view.setup(state: .on)
        view.setRefreshTimer(timeInterval: 2)
        return view
    }
    
    private func playliveView() {
        let player = AVPlayer(url: Gopro3API.liveStreamURL)
        player.rate = 1
        player.isMuted = true
        liveViewController.player = player
        liveViewContainer.isHidden = false
        liveVideoButton.setImage(UIImage(systemName: "stop.circle"), for: .normal)
    }
    
    private func stopLiveView() {
        liveViewController.player?.pause()
        liveViewController.player = nil
        liveViewContainer.isHidden = true
        liveVideoButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
    }
    
    private func setup(state: CameraControlViewState) {
        switch state {
        case .off:
            stopLiveView()
            powerButton.tintColor = .systemGray
            liveVideoButton.isEnabled = false
            recordingTimeLabel.text = ""
            batteryStatusLabel.text = "n/a"
            cameraTimeLabel.text = ""
            cameraTimeLabel.textColor = .systemGray
            recordingButton.isEnabled = false
            recordingButton.isSelected = false
        case .on:
            powerButton.tintColor = .white
            powerButton.isHidden = false
            liveVideoButton.isEnabled = true
            recordingTimeLabel.text = ""
            cameraTimeLabel.textColor = .systemGray
            recordingButton.isEnabled = true
            recordingButton.isSelected = false
        case .recording:
            powerButton.isHidden = true
            cameraTimeLabel.textColor = .white
            recordingButton.isEnabled = true
            recordingButton.isSelected = true
        }
    }
    
    private func refreshCameraStatus() {
        Gopro3API.requestData(.status)
        .done {
            self.decodeCameraStatus(data: $0)
        }.catch { error in
            switch error {
            case NetworkError.gone:
                // camera is off
                self.cameraState = .off
                self.timer?.invalidate()
                self.timer = nil
            case NetworkError.unaviable(let message):
                alert(message: "Payload camera connection lost", informative: message, delay: 3)
                self.timer?.invalidate()
                self.timer = nil
            default:
                error.alert()
            }
        }
    }
    
    private func decodeCameraStatus(data: Data) {
        let status = GoproStatus(data: data)
        cameraState = status.recording ? .recording : .on
        batteryStatusLabel.text = status.battery
        cameraTime = status.videoRemaining
        if status.recording {
            let (hour, min, sec) = status.videoProgress
            recordingTimeLabel.text = String(format: "%2.2d:%2.2d:%2.2d", hour, min, sec)
        }
    }
    
    private func setRefreshTimer(timeInterval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] in
            self?.refreshCameraStatus()
            if $0.timeInterval == 2 {
                self?.setRefreshTimer(timeInterval: 10)
            }
        }
    }
    
    @IBAction func powerButtonPress(_ sender: Any) {
        let powerOn: Bool
        switch cameraState {
        case .off       : powerOn = true
        case .on        : powerOn = false
        case .recording : return
        }
        
        Gopro3API.request(.power(on: powerOn))
        .then { (Void) -> Promise<Data> in
            if powerOn {
                return Gopro3API.attempt(retryCount: 10, delay: .seconds(1)) {
                    Gopro3API.requestData(.status)
                }
            } else {
                return Promise<Data>.value(Data())
            }
        }.done { _ in
            if powerOn {
                self.setRefreshTimer(timeInterval: 2)
            } else {
                self.timer?.invalidate()
                self.timer = nil
            }
            self.cameraState = powerOn ? .on : .off
        }.catch {
            $0.alert()
        }
    }
    
    @IBAction func recordingButtonPress(_ sender: Any) {
        let shotOn: Bool
        switch cameraState {
        case .off       : return
        case .on        : shotOn = true
        case .recording : shotOn = false
        }
        Gopro3API.attempt(retryCount: 5, delay: .milliseconds(500)) {
            Gopro3API.request(.shot(on: shotOn))
        }.done {
            self.cameraState = shotOn ? .recording : .on
            self.setRefreshTimer(timeInterval: shotOn ? 1 : 2)
        }.catch {
            $0.alert()
        }
    }
    
    @IBAction func liveVideoButtonPress(_ sender: Any) {
        if liveViewController.player == nil {
            playliveView()
        } else {
            stopLiveView()
        }
    }
}
