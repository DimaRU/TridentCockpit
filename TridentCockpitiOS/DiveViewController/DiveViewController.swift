/////
////  DiveViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import CoreLocation
import FastRTPSSwift
import AVKit

class DiveViewController: UIViewController {
    @IBOutlet unowned var videoView: VideoView!

    @IBOutlet unowned var indicatorsView: UIView!
    @IBOutlet unowned var videoSizingButton: UIButton!
    @IBOutlet unowned var depthLabel: UILabel!
    @IBOutlet unowned var tempLabel: UILabel!
    @IBOutlet unowned var batteryTimeLabel: UILabel!
    @IBOutlet unowned var batterySymbol: UIImageView!
    @IBOutlet unowned var propellerButton: UIButton!
    @IBOutlet unowned var stabilizeSwitch: PWSwitch!
    @IBOutlet unowned var stabilizeLabel: UILabel!
    @IBOutlet unowned var telemetryOverlayLabel: UILabel!

    @IBOutlet unowned var lightButton: UIButton!
    @IBOutlet unowned var headingView: RovHeadingView!
    @IBOutlet unowned var throttleJoystickView: TouchJoystickView!
    @IBOutlet unowned var yawPitchJoystickView: TouchJoystickView!
    @IBOutlet unowned var liveViewContainer: AuxCameraPlayerView!

    private let locationManager = CLLocationManager()
    private var cameraControlView: CameraControlView?
    private var auxCameraView: AuxCameraControlView?
    private var streamStatsView: StreamStatsView?
    private var videoProcessor: VideoProcessor!
    private unowned var videoStreamer: VideoStreamer?
    private let videoProcessorMulticastDelegate = VideoProcessorMulticastDelegate([])
    private let tridentControl = TridentControl()
    private var savedCenter: [UIView: CGPoint] = [:]
    private var equalizerView: EqualizerView!

    private var lightOn = false
    let vehicleId: String
    private var rovBeacon: RovBeacon?
    private var rovSafetyState: RovSafetyState?
    
    @Average(5) private var depth: Float
    @Average(10) private var temperature: Double

    private func setupAverage() {
        _depth.configure { [unowned self] avg in
            DispatchQueue.main.async {
                self.depthLabel.text = String(format: "%.1f", avg)
            }
        }

        _temperature.configure { [unowned self] avg in
            DispatchQueue.main.async {
                self.tempLabel.text = String(format: "%.1f", avg)
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

    init?(coder: NSCoder, vehicleId: String, videoStreamer: VideoStreamer?) {
        self.vehicleId = vehicleId
        self.videoStreamer = videoStreamer
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        depthLabel.text = "n/a"
        tempLabel.text = "n/a"
        batteryTimeLabel.text = "n/a"
        depthLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        tempLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        throttleJoystickView.delegate = tridentControl
        yawPitchJoystickView.delegate = tridentControl
        #if targetEnvironment(macCatalyst)
        throttleJoystickView.isHidden = true
        yawPitchJoystickView.isHidden = true
        #else
        if let window = view.window?.windowScene?.keyWindow {
            let bounds = window.bounds
            let offset: CGFloat = UITraitCollection.current.verticalSizeClass == .compact ? 185 : 250
            throttleJoystickView.center = CGPoint(x: bounds.minX + offset, y: bounds.maxY - offset)
            yawPitchJoystickView.center = CGPoint(x: bounds.maxX - offset, y: bounds.maxY - offset)
        } else {
            print("Window not found!")
        }

        #endif

        setupAverage()
        
        indicatorsView.backgroundColor = UIColor(named: "cameraControlBackground")!
        lightButton.cornerRadius = 5
        lightButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        let orientation = RovQuaternion(x: -0.119873046875, y: 0.99249267578125, z: 0.01611328125, w: 0.01910400390625)
        headingView.setOrientation(orientation)
        
        tridentControl.setup(delegate: self)

        videoProcessorMulticastDelegate.add(videoView)
        videoProcessor = VideoProcessor(delegate: videoProcessorMulticastDelegate)
        setVideoSizing(fill: Preference.videoSizingFill)

        if Preference.recordOnboardVideo || Preference.recordPilotVideo {
            cameraControlView = CameraControlView.instantiate(videoProcessorMulticastDelegate)
            view.addSubview(cameraControlView!)
        }
        if let videoStreamer = videoStreamer {
            videoProcessorMulticastDelegate.add(videoStreamer)
            let streamStatsView = StreamStatsView.instantiate()
            view.addSubview(streamStatsView)
            NSLayoutConstraint.activate([
                streamStatsView.topAnchor.constraint(equalTo: indicatorsView.bottomAnchor, constant: 3),
                streamStatsView.centerXAnchor.constraint(equalTo: indicatorsView.centerXAnchor)
            ])
            
            videoStreamer.delegate = streamStatsView
            streamStatsView.state(published: videoStreamer.isPublished) // May be already dead
            self.streamStatsView = streamStatsView
        }
        liveViewContainer.isHidden = true
        if Gopro3API.isConnected {
            guard let liveViewController = children.first(where: { $0 is AVPlayerViewController}) as? AVPlayerViewController else { return }
            auxCameraView = AuxCameraControlView.instantiate(liveViewContainer: liveViewContainer,
                                                             liveViewController: liveViewController)
            view.addSubview(auxCameraView!)
            auxCameraView?.delegate = self
        }

        equalizerView = Bundle.main.loadNibNamed("EqualizerView", owner: nil, options: nil)?.first as? EqualizerView
        view.addSubview(equalizerView)
        NSLayoutConstraint.activate([
            equalizerView.topAnchor.constraint(equalTo: indicatorsView.bottomAnchor, constant: 8),
            equalizerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8),
        ])
        equalizerView.isHidden = true

        startRTPS()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
        locationManager.requestLocation()
        
        #if DEBUG
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(batterySymbolTap(sender:)))
        gestureRecognizer.numberOfTapsRequired = 2
        batterySymbol.addGestureRecognizer(gestureRecognizer)
        batterySymbol.isUserInteractionEnabled = true
        #endif
    }

    #if DEBUG
    @objc func batterySymbolTap(sender: UITapGestureRecognizer) {
        playDemoVideo()
    }
    #endif
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        cameraControlView?.superViewDidResize(to: size)
        headingView.superViewDidResize(to: size)
        auxCameraView?.superViewDidResize(to: size)
        liveViewContainer?.superViewDidResize(to: size)

        guard let before = self.view.window?.windowScene?.interfaceOrientation else { return }
        coordinator.animate(alongsideTransition: nil) { _ in
            guard let after = self.view.window?.windowScene?.interfaceOrientation else { return }
            if before != after {
                self.setHeadingOrienation()
                self.updateLightButtonConstraint()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tridentControl.controllerName != nil {
            throttleJoystickView.isHidden = true
            yawPitchJoystickView.isHidden = true
        }

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        setHeadingOrienation()
        updateLightButtonConstraint()
        
        if let controllerName = tridentControl.controllerName {
            alertMessage(message: controllerName + " connected", delay: 3)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewWillLayoutSubviews() {
        for view in view.subviews where view is SaveCenter {
            savedCenter[view] = view.center
        }
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for (view, center) in savedCenter {
            view.center = center
        }
        savedCenter = [:]
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard touch.view == view || touch.view is TouchJoystickView else { continue }
            let location = touch.location(in: view)
            if location.x < view.bounds.midX {
                throttleJoystickView.touchBegan(touch: touch)
            } else {
                yawPitchJoystickView.touchBegan(touch: touch)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            throttleJoystickView.touchMoved(touch: touch)
            yawPitchJoystickView.touchMoved(touch: touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            throttleJoystickView.touchEnded(touch: touch)
            yawPitchJoystickView.touchEnded(touch: touch)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            throttleJoystickView.touchEnded(touch: touch)
            yawPitchJoystickView.touchEnded(touch: touch)
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        if #available(macCatalyst 13.4, iOS 13.4, *) {
            for press in presses {
                guard let key = press.key else { continue }
                didHandleEvent = didHandleEvent || tridentControl.process(key: key, began: true)
            }
        }
        if !didHandleEvent {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        if #available(macCatalyst 13.4, iOS 13.4, *) {
            for press in presses {
                guard let key = press.key else { continue }
                didHandleEvent = didHandleEvent || tridentControl.process(key: key, began: false)
            }
        }
        if !didHandleEvent {
            super.pressesEnded(presses, with: event)
        }
    }

    @IBAction func closeButtonPress(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("Leave Pilot Mode?", comment: ""),
                                      message: NSLocalizedString("Are you sure you want to leave?", comment: ""),
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.dismiss(animated: true) {
                self.cleanup()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    @IBAction func equalizerButtonPress(_ sender: UIButton) {
        if equalizerView.isHidden {
            sender.layer.borderWidth = 1
            sender.layer.borderColor = UIColor.white.cgColor
            equalizerView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.equalizerView.alpha = 1
            }
        } else {
            sender.layer.borderWidth = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.equalizerView.alpha = 0
            }) { _ in
                self.equalizerView.isHidden = true
            }
        }
    }
    
    @IBAction func lightButtonPress(_ sender: Any) {
        switchLight()
    }
    
    @IBAction func propellerButtonPress(_ sender: Any) {
        let newSpeed = tridentControl.motorSpeed.rawValue + 1
        tridentControl.motorSpeed = TridentControl.MotorSpeed(rawValue: newSpeed) ?? .first
        updatePropellerButtonState()
    }
    
    @IBAction func stabilizeAction(_ sender: Any) {
        let state = stabilizeSwitch.on
        Preference.tridentStabilize = state
        let controllerStatus = RovControllerStatus(vehicleId: vehicleId,
                                                   controllerId: .trident,
                                                   state: state ? .enabled : .disabled)
        FastRTPS.send(topic: .rovControllerStateRequested, ddsData: controllerStatus)
    }
    
    @IBAction func toggleTelemetryOverlayAction(_ sender: Any) {
        Preference.videoOverlayMode.toggle()
        FastRTPS.send(topic: .rovVideoOverlayModeCommand, ddsData: Preference.videoOverlayMode ? "on" : "off")
    }
    
    @IBAction func videoSizingButtonTap(_ sender: UIButton) {
        setVideoSizing(fill: !Preference.videoSizingFill)
    }
    
    private func updateLightButtonConstraint() {
        guard
            let orientation = self.view.window?.windowScene?.interfaceOrientation,
            let constraint = view.constraints.first(where: { $0.identifier == "trailing" }) else { return }
        if orientation == .landscapeLeft, view.safeAreaInsets.right > 0 {
            constraint.constant = view.safeAreaInsets.right - 6
        } else {
            constraint.constant = 13
        }
    }
    
    private func setHeadingOrienation() {
        guard let orientation = self.view.window?.windowScene?.interfaceOrientation else { return }
        switch orientation{
        case .portrait           : locationManager.headingOrientation = .portrait
        case .portraitUpsideDown : locationManager.headingOrientation = .portraitUpsideDown
        case .landscapeLeft      : locationManager.headingOrientation = .landscapeLeft
        case .landscapeRight     : locationManager.headingOrientation = .landscapeRight
        default:
            break
        }
    }
   
    private func setTelemetryOverlay(mode: String) {
        switch mode {
        case "on":
            telemetryOverlayLabel.text = "Telemetry:ON"
        case "off":
            telemetryOverlayLabel.text = "Telemetry:OFF"
        default:
            assertionFailure("illegal mode: \(mode)")
        }
    }
    
    private func setVideoSizing(fill: Bool) {
        Preference.videoSizingFill = fill
        videoSizingButton.isSelected = fill
        videoView.setGravity(fill: fill)
    }
    
    private func setStabilize(status: Bool) {
        stabilizeSwitch.setOn(status , animated: true)
        if status {
            if rovSafetyState?.state == .on {
                stabilizeLabel.text = "Stabilized-paused"
            } else {
                stabilizeLabel.text = "Stabilized"
            }
        } else {
            stabilizeLabel.text = "Stabilize disabled"
        }

    }
       
    private func startRTPS() {
        registerReaders()
        registerWriters()
        
//        rovProvision()
    }
    
    func cleanup() {
        tridentControl.disable()
        cameraControlView?.cleanup()
        FastRTPS.resignAll()
        videoProcessor.cleanup()
        auxCameraView?.cleanup()
    }
    
    private func rovProvision() {
        tridentControl.enable()
        cameraControlView?.start()

        let timeMs = UInt(Date().timeIntervalSince1970 * 1000)
        FastRTPS.send(topic: .rovDatetime, ddsData: String(timeMs))
        FastRTPS.send(topic: .rovVideoOverlayModeCommand, ddsData: Preference.videoOverlayMode ? "on" : "off")
        let controllerStatus = RovControllerStatus(vehicleId: vehicleId,
                                                   controllerId: .trident,
                                                   state: Preference.tridentStabilize ? .enabled : .disabled)
        FastRTPS.send(topic: .rovControllerStateRequested, ddsData: controllerStatus)
    }

    private func registerReaders() {
        FastRTPS.registerReader(topic: .rovCamFwdH2640Video) { [unowned self] (videoData: RovVideoData) in
            self.videoProcessor.decodeVideo(data: videoData.data, timestamp: videoData.timestamp)
        }

        FastRTPS.registerReader(topic: .rovTempWater) { [unowned self] (temp: RovTemperature) in
            self.temperature = temp.temperature.temperature
        }
        
        FastRTPS.registerReader(topic: .rovDepth) { [unowned self] (depth: RovDepth) in
            self.depth = depth.depth
        }
        
        FastRTPS.registerReader(topic: .rovFuelgaugeHealth) { [unowned self] (health: RovFuelgaugeHealth) in
            self.batteryTime = health.average_time_to_empty_mins
        }
        
        FastRTPS.registerReader(topic: .rovFuelgaugeStatus) { [unowned self] (status: RovFuelgaugeStatus) in
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

        FastRTPS.registerReader(topic: .rovAttitude) { [unowned self] (attitude: RovAttitude) in
            let orientation = attitude.orientation
            self.headingView.setOrientation(orientation)
//            print((1 + orientation.yaw / .pi) * 180)
        }
        
        FastRTPS.registerReader(topic: .rovLightPowerCurrent) { [unowned self] (lightPower: RovLightPower) in
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
        
        FastRTPS.registerReader(topic: .rovVideoOverlayModeCurrent) { [unowned self] (overlayMode: String) in
            DispatchQueue.main.async {
                self.setTelemetryOverlay(mode: overlayMode)
            }
        }

        FastRTPS.registerReader(topic: .rovControllerStateCurrent) { [unowned self] (controllerStatus: RovControllerStatus) in
            guard controllerStatus.controllerId == .trident else { return }
            DispatchQueue.main.async {
                self.setStabilize(status: controllerStatus.state == .enabled)
            }
        }

        FastRTPS.registerReader(topic: .rovSafety) { [unowned self] (rovSafetyState: RovSafetyState) in
            DispatchQueue.main.async {
                self.rovSafetyState = rovSafetyState
                self.setStabilize(status: self.stabilizeSwitch.on)
            }
            
        }

        FastRTPS.registerReader(topic: .rovBeacon) { [unowned self] (rovBeacon: RovBeacon) in
            guard self.rovBeacon == nil else { return }
            DispatchQueue.main.async {
                self.rovBeacon = rovBeacon
                self.rovProvision()
                FastRTPS.removeReader(topic: .rovBeacon)
            }
        }

    }
    
    private func registerWriters() {
        FastRTPS.registerWriter(topic: .rovLightPowerRequested, ddsType: RovLightPower.self)
        FastRTPS.registerWriter(topic: .rovDatetime, ddsType: String.self)
        FastRTPS.registerWriter(topic: .rovVideoOverlayModeCommand, ddsType: String.self)
        FastRTPS.registerWriter(topic: .rovVidSessionReq, ddsType: RovVideoSessionCommand.self)
        FastRTPS.registerWriter(topic: .rovControlTarget, ddsType: RovTridentControlTarget.self)
        FastRTPS.registerWriter(topic: .rovControllerStateRequested, ddsType: RovControllerStatus.self)
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
        let tridentCommand = RovTridentControlTarget(id: vehicleId, pitch: pitch, yaw: yaw, thrust: thrust, lift: lift)
        FastRTPS.send(topic: .rovControlTarget, ddsData: tridentCommand)
    }
    
    func updatePropellerButtonState() {
        switch tridentControl.motorSpeed {
        case .first:
            propellerButton.setImage(UIImage(named: "Prop 1"), for: .normal)
        case .second:
            propellerButton.setImage(UIImage(named: "Prop 2"), for: .normal)
        case .third:
            propellerButton.setImage(UIImage(named: "Prop 3"), for: .normal)
        }
    }
    
    func switchLight() {
        let lightPower = RovLightPower(id: "fwd", power: lightOn ? 0:1)
        FastRTPS.send(topic: .rovLightPowerRequested, ddsData: lightPower)
    }
    
    func switchRecording() {
        cameraControlView?.switchRecording()
    }
    
}

extension DiveViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.magneticHeading
        let cameraHeading = -heading
        let yaw = Float(cameraHeading / 180 * .pi)
        headingView.setCameraPos(yaw: yaw)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        cameraControlView?.currentLocation = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

final class VideoProcessorMulticastDelegate: VideoProcessorDelegate {
    private let multicast = MulticastDelegate<VideoProcessorDelegate>()
    
    init(_ delegates: [VideoProcessorDelegate]) {
        delegates.forEach(multicast.add)
    }
    
    func add(_ delegate: VideoProcessorDelegate) {
        multicast.add(delegate)
    }
    
    func remove(_ delegate: VideoProcessorDelegate) {
        multicast.remove(delegate)
    }
    
    func processNal(sampleBuffer: CMSampleBuffer) {
        multicast.invoke{ $0.processNal(sampleBuffer: sampleBuffer) }
    }
    
    func set(format: CMVideoFormatDescription, time: CMTime) {
        multicast.invoke { $0.set(format: format, time: time) }
    }
    
    func cleanup() {
        multicast.invoke{ $0.cleanup() }
    }
}
