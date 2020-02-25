/////
////  DiveViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import SceneKit
import FastRTPSBridge

class DiveViewController: UIViewController, StoryboardInstantiable {
    @IBOutlet weak var videoView: VideoView!

    @IBOutlet weak var indicatorsView: UIView!
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var batteryTimeLabel: UILabel!
    @IBOutlet weak var batterySymbol: UIImageView!
    @IBOutlet weak var propellerButton: UIButton!
    @IBOutlet weak var stabilizeSwitch: PWSwitch!
    @IBOutlet weak var stabilizeLabel: UILabel!
    
    @IBOutlet weak var cameraControlView: CameraControlView!
    @IBOutlet weak var recordingButton: CameraButton!
    @IBOutlet weak var cameraTimeLabel: UILabel!
    @IBOutlet weak var recordingTimeLabel: UILabel!

    @IBOutlet weak var lightButton: UIButton!
    @IBOutlet weak var tridentView: RovModelView!

    private var auxCameraView: AuxCameraControlView?
    private var videoDecoder: VideoDecoder!
    private let tridentControl = TridentControl()
    
    private var lightOn = false
    private var videoSessionId: UUID?
    let vehicleId: String
    private var rovBeacon: RovBeacon?
    
    @Average(5) private var depth: Float
    @Average(10) private var temperature: Double

    private func setupAverage() {
        _depth.configure { [weak self] avg in
            DispatchQueue.main.async {
                self?.depthLabel.text = String(format: "%.1f", avg)
            }
        }

        _temperature.configure { [weak self] avg in
            DispatchQueue.main.async {
                self?.tempLabel.text = String(format: "%.1f", avg)
            }
        }
    }
    
    private var batteryTime: Int32 = 0 {
        didSet {
            guard batteryTime != 65535 else {
                return
            }
            var time = ""
            if batteryTime / 60 != 0 {
                time += String(batteryTime / 60) + "h"
            }
            if batteryTime % 60 != 0 {
                time += String(batteryTime % 60) + "m"
            }
            DispatchQueue.main.async {
                self.batteryTimeLabel.text = time
            }
        }
    }

    private var cameraTime: UInt32 = 0 {
        didSet {
            var time = "Remaining time:\n"
            if cameraTime / 60 != 0 {
                time += String(cameraTime / 60) + "h "
            }
            if cameraTime % 60 != 0 {
                time += String(cameraTime % 60) + "m"
            }
            DispatchQueue.main.async {
                self.cameraTimeLabel.text = time
            }
        }
    }
    
    init?(coder: NSCoder, vehicleId: String) {
      self.vehicleId = vehicleId
      super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    #if DEBUG
    deinit {
        print(String(describing: self), #function)
    }
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        depthLabel.text = "n/a"
        tempLabel.text = "n/a"
        batteryTimeLabel.text = "n/a"
        cameraTimeLabel.text = ""
        recordingTimeLabel.text = ""
        cameraTimeLabel.textColor = .systemGray
        depthLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        tempLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)

        setupAverage()
        
        indicatorsView.backgroundColor = UIColor(named: "cameraControlBackground")!
        lightButton.layer.cornerRadius = 5
        lightButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        let node = tridentView.modelNode()
        node.orientation = RovQuaternion(x: -0.119873046875, y: 0.99249267578125, z: 0.01611328125, w: 0.01910400390625).scnQuaternion()
        
        tridentControl.setup(delegate: self)
        videoDecoder = VideoDecoder(sampleBufferLayer: videoView.sampleBufferLayer)

        if Gopro3API.isConnected {
            auxCameraView = AuxCameraControlView.instantiate(superView: view)
            auxCameraView?.delegate = self
        }
        
        startRTPS()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        cameraControlView.superViewDidResize(to: size)
        tridentView.superViewDidResize(to: size)
        auxCameraView?.superViewDidResize(to: size)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    @IBAction func closeButtonPress(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("Leave Pilot Mode?", comment: ""),
                                      message: NSLocalizedString("Are you sure you want to leave?", comment: ""),
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.tridentControl.disable()
            FastRTPS.resignAll()
            self.videoDecoder.cleanup()
            self.dismiss(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    @IBAction func recordingButtonPress(_ sender: Any) {
        switchRecording()
    }
    
    @IBAction func lightButtonPress(_ sender: Any) {
        switchLight()
    }
    
    @IBAction func propellerButtonPress(_ sender: Any) {
        guard tridentControl.motorSpeed != nil else { return }
        let newSpeed = tridentControl.motorSpeed!.rawValue + 1
        tridentControl.motorSpeed = TridentControl.MotorSpeed(rawValue: newSpeed)
        if tridentControl.motorSpeed == nil {
            tridentControl.motorSpeed = .first
        }
        updatePropellerButtonState()
    }
    
    @IBAction func relativeYawAction(_ sender: Any) {
        let node = tridentView.modelNode()
        let o = node.orientation
        let q = RovQuaternion(x: Double(-o.x), y: Double(-o.z), z: Double(-o.y), w: Double(o.w))
        tridentView.setCameraPos(yaw: Float(-q.yaw))
    }
    
    @IBAction func absoluteYawAction(_ sender: Any) {
        tridentView.setCameraPos(yaw: .pi)
    }
    
    @IBAction func stabilizeAction(_ sender: Any) {
        let controllerStatus = RovControllerStatus(vehicleId: vehicleId,
                                                   controllerId: .trident,
                                                   state: !Preference.tridentStabilize ? .enabled : .disabled)
        FastRTPS.send(topic: .rovControllerStateRequested, ddsData: controllerStatus)
    }
    
    @IBAction func telemetryOverlayAction(_ sender: Any) {
        FastRTPS.send(topic: .rovVideoOverlayModeCommand, ddsData: !Preference.videoOverlayMode ? "on" : "off")
    }
    
    private func setTelemetryOverlay(mode: String) {
        switch mode {
        case "on":
            Preference.videoOverlayMode = true
        case "off":
            Preference.videoOverlayMode = false
        default:
            print("illegal mode:", mode)
        }
        
//        let menuItem = NSApplication.shared.mainMenu?.recursiveSearch(tag: 4)
//        menuItem!.state = Preference.videoOverlayMode ? .on:.off
    }
    
    private func setController(status: RovControllerStatus) {
        guard status.controllerId == .trident else { return }
        Preference.tridentStabilize = (status.state == .enabled)
        stabilizeSwitch.setOn((status.state == .enabled) , animated: true)
        if status.state == .enabled {
            stabilizeLabel.text = "Stabilize: stabilized"
        } else {
            stabilizeLabel.text = "Stabilize: disabled"
        }
    }
       
    private func startRTPS() {
        registerReaders()
        registerWriters()
        
//        rovProvision()
    }
    
    private func rovProvision() {
        tridentControl.enable()

        let timeMs = UInt(Date().timeIntervalSince1970 * 1000)
        FastRTPS.send(topic: .rovDatetime, ddsData: String(timeMs))
        FastRTPS.send(topic: .rovVideoOverlayModeCommand, ddsData: Preference.videoOverlayMode ? "on" : "off")
        let videoReq = RovVideoSessionCommand(sessionID: "", metadata: "", request: .stopped, response: .unknown, reason: "")
        FastRTPS.send(topic: .rovVidSessionReq, ddsData: videoReq)
        let lightPower = RovLightPower(id: "fwd", power: 0)
        FastRTPS.send(topic: .rovLightPowerRequested, ddsData: lightPower)
        let controllerStatus = RovControllerStatus(vehicleId: vehicleId,
                                                   controllerId: .trident,
                                                   state: Preference.tridentStabilize ? .enabled : .disabled)
        FastRTPS.send(topic: .rovControllerStateRequested, ddsData: controllerStatus)
    }

    private func registerReaders() {
        FastRTPS.registerReader(topic: .rovCamFwdH2640Video) { [weak self] (videoData: RovVideoData) in
            self?.videoDecoder.decodeVideo(data: videoData.data, timestamp: videoData.timestamp)
        }

        FastRTPS.registerReader(topic: .rovTempWater) { [weak self] (temp: RovTemperature) in
            self?.temperature = temp.temperature.temperature
        }
        
        FastRTPS.registerReader(topic: .rovDepth) { [weak self] (depth: RovDepth) in
            self?.depth = depth.depth
        }
        
        FastRTPS.registerReader(topic: .rovFuelgaugeHealth) { [weak self] (health: RovFuelgaugeHealth) in
            self?.batteryTime = health.average_time_to_empty_mins
        }
        
        FastRTPS.registerReader(topic: .rovFuelgaugeStatus) { [weak self] (status: RovFuelgaugeStatus) in
            guard let self = self else { return }
            guard self.batteryTime == 65535 else { return }
        
            DispatchQueue.main.async {
                self.batteryTimeLabel.text = String(format: "charge: %.0f%%", status.state.percentage * 100)
                switch status.state.percentage {
                case ..<0.10:     self.batterySymbol.image = UIImage(systemName: "battery.0")
                case 0.10..<0.30: self.batterySymbol.image = UIImage(systemName: "battery.25")
                default:          self.batterySymbol.image = UIImage(systemName: "battery.100")
                }
            }
        }

        FastRTPS.registerReader(topic: .rovRecordingStats) { [weak self] (recordingStats: RovRecordingStats) in
            self?.cameraTime = recordingStats.estRemainingRecTimeS / 60
        }
        
        FastRTPS.registerReader(topic: .rovAttitude) { [weak self] (attitude: RovAttitude) in
            let node = self?.tridentView.modelNode()
            let orientation = attitude.orientation
            node?.orientation = orientation.scnQuaternion()
//            print((1 + orientation.yaw / .pi) * 180)
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
                    self.cameraTimeLabel.textColor = .white

                case .stopped:
                    self.videoSessionId = nil
                    self.recordingTimeLabel.text = ""
                    self.cameraTimeLabel.textColor = .systemGray
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
                    self.alert(message: "Recording", informative: "Already in progress")
                case .rejectedNoSpace:
                    self.videoSessionId = nil
                    self.alert(message: "Recording", informative: "No space left")
                }
            }
        }
        
        FastRTPS.registerReader(topic: .rovLightPowerCurrent) { [weak self] (lightPower: RovLightPower) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if lightPower.power > 0 {
                    // Light On
                    self.lightOn = true
                    self.lightButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
                    self.lightButton.tintColor = .white
                    self.lightButton.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                } else {
                    // Light Off
                    self.lightOn = false
                    self.lightButton.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal)
                    self.lightButton.tintColor = .black
                    self.lightButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
                }
            }
        }
        
        FastRTPS.registerReader(topic: .rovVideoOverlayModeCurrent) { [weak self] (overlayMode: String) in
            DispatchQueue.main.async {
                self?.setTelemetryOverlay(mode: overlayMode)
            }
        }

        FastRTPS.registerReader(topic: .rovControllerStateCurrent) { [weak self] (controllerStatus: RovControllerStatus) in
            DispatchQueue.main.async {
                self?.setController(status: controllerStatus)
            }
        }

        FastRTPS.registerReader(topic: .rovBeacon) { [weak self] (rovBeacon: RovBeacon) in
            guard self?.rovBeacon == nil else { return }
            DispatchQueue.main.async {
                self?.rovBeacon = rovBeacon
                self?.rovProvision()
                FastRTPS.removeReader(topic: .rovBeacon)
            }
        }

    }
    
    private func registerWriters() {
        FastRTPS.registerWriter(topic: .rovLightPowerRequested, ddsType: RovLightPower.self)
        FastRTPS.registerWriter(topic: .rovDatetime, ddsType: String.self)
        FastRTPS.registerWriter(topic: .rovVideoOverlayModeCommand, ddsType: String.self)
        FastRTPS.registerWriter(topic: .rovVidSessionReq, ddsType: RovVideoSessionCommand.self)
        FastRTPS.registerWriter(topic: .rovDepthConfigRequested, ddsType: RovDepthConfig.self)
        FastRTPS.registerWriter(topic: .rovControlTarget, ddsType: RovTridentControlTarget.self)
        FastRTPS.registerWriter(topic: .rovControllerStateRequested, ddsType: RovControllerStatus.self)
        FastRTPS.registerWriter(topic: .rovFirmwareCommandReq, ddsType: RovFirmwareCommand.self)
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
    }
    
    private func stopRecordingSession(id: UUID) {
        let videoSessionCommand = RovVideoSessionCommand(sessionID: id.uuidString.lowercased(),
                                                         metadata: "",
                                                         request: .stopped,
                                                         response: .unknown,
                                                         reason: "")
        FastRTPS.send(topic: .rovVidSessionReq, ddsData: videoSessionCommand)
    }

}

extension DiveViewController: TridentControlDelegate {
    func switchAuxRecording() {
        auxCameraView?.recordingButtonPress(auxCameraView!)
    }
    
    func switchAuxPower() {
        auxCameraView?.powerButtonPress(auxCameraView!)
    }
    
    func control(pitch: Float, yaw: Float, thrust: Float, lift: Float) {
        let tridentCommand = RovTridentControlTarget(id: "control", pitch: pitch, yaw: yaw, thrust: thrust, lift: lift)
        FastRTPS.send(topic: .rovControlTarget, ddsData: tridentCommand)
    }
    
    func updatePropellerButtonState() {
        switch tridentControl.motorSpeed {
        case .first?:
            propellerButton.setImage(UIImage(named: "Prop 1"), for: .normal)
        case .second?:
            propellerButton.setImage(UIImage(named: "Prop 2"), for: .normal)
        case .third?:
            propellerButton.setImage(UIImage(named: "Prop 3"), for: .normal)
        case nil:
            break
        }
    }
    
    func switchLight() {
        let lightPower = RovLightPower(id: "fwd", power: lightOn ? 0:1)
        FastRTPS.send(topic: .rovLightPowerRequested, ddsData: lightPower)
    }
    
    func switchRecording() {
        if let videoSessionId = videoSessionId {
            stopRecordingSession(id: videoSessionId)
        } else {
            startRecordingSession(id: UUID())
        }
    }
    
}
