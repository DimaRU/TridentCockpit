/////
////  MaintenanceViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

class MaintenanceViewController: NSViewController {
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet weak var batteryChargeLabel: NSTextField!
    @IBOutlet weak var batteryCycleLabel: NSTextField!
    @IBOutlet weak var internalPressureLabel: NSTextField!
    @IBOutlet weak var internalTemperatureLabel: NSTextField!
    @IBOutlet weak var pressureLabel: NSTextField!
    @IBOutlet weak var temperatureLabel: NSTextField!
    
    @Average(10) private var pressure: Double
    @Average(10) private var temperature: Double

    private var internalPressure: Double = 0 {
        didSet {
            DispatchQueue.main.async {
                self.internalPressureLabel.stringValue = String(format: "%.3f kPa", self.internalPressure)
            }
        }
    }
    private var internalTemperature: Double = 0 {
        didSet {
            DispatchQueue.main.async {
                self.internalTemperatureLabel.stringValue = String(format: "%.2f", self.internalTemperature)
            }
        }
    }

    #if DEBUG
    deinit {
        print(className, #function)
    }
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(named: "splashColor")!.cgColor
        configurAverage()
        registerReaders()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.toolbar = toolbar
    }

    @IBAction func closeButtonPress(_ sender: Any) {
        FastRTPS.resignAll()
        transitionBack(options: .slideRight)
    }
    
    private func configurAverage() {
        _pressure.configure { [weak self] avg in
            DispatchQueue.main.async {
                self?.pressureLabel.stringValue = String(format: "%.3f kPa", avg)
            }
        }
        _temperature.configure { [weak self] avg in
            DispatchQueue.main.async {
                self?.temperatureLabel.stringValue = String(format: "%.2f", avg)
            }
        }
    }

    private func registerReaders() {
        FastRTPS.registerReader(topic: .rovTempWater) { [weak self] (temp: RovTemperature) in
            self?.temperature = temp.temperature.temperature
        }

        FastRTPS.registerReader(topic: .rovDepth) { [weak self] (depth: RovDepth) in
            self?.pressure = depth.pressure.fluidPressure / 10
        }

        FastRTPS.registerReader(topic: .rovTempInternal) { [weak self] (temp: RovTemperature) in
            self?.internalTemperature = temp.temperature.temperature
        }

        FastRTPS.registerReader(topic: .rovPressureInternal) { [weak self] (baro: RovBarometer) in
            self?.internalPressure = baro.pressure.fluidPressure / 10
        }

        FastRTPS.registerReader(topic: .rovFuelgaugeStatus) { [weak self] (status: RovFuelgaugeStatus) in
            DispatchQueue.main.async {
                self?.batteryChargeLabel.stringValue = String(format: "%.0f%%", status.state.percentage * 100)
            }
        }

        FastRTPS.registerReader(topic: .rovFuelgaugeHealth) { [weak self] (health: RovFuelgaugeHealth) in
            DispatchQueue.main.async {
                self?.batteryCycleLabel.stringValue = String(health.cycle_count)
            }
        }

//        FastRTPS.registerReader(topic: .rovSubsystemStatus) { (status: RovSubsystemStatus) in
//            print("status:", status.subsystemId.rawValue, status.substate)
//        }
//        FastRTPS.registerReader(topic: .rovFirmwareStatus) { (firmwareStatus: RovFirmwareStatus) in
//            print(firmwareStatus)
//        }
//        FastRTPS.registerReader(topic: .rovFirmwareServiceStatus) { (firmwareServiceStatus: RovFirmwareServiceStatus) in
//            print(firmwareServiceStatus)
//        }
//        FastRTPS.registerReader(topic: .rovFirmwareCommandRep) { (command: RovFirmwareCommand) in
//            print(command)
//        }
//        FastRTPS.registerReader(topic: .rovControlCurrent) { (control: RovTridentControlTarget) in
//            print(control)
//        }
//        FastRTPS.registerReader(topic: .navTrackingCurrent) { (cameraObjectTrack: RovCameraObjectTrack) in
//            print(cameraObjectTrack)
//        }
//        FastRTPS.registerReader(topic: .mcuI2cStats) { (stats: I2CStats) in
//            print(stats)
//        }
//        FastRTPS.registerReader(topic: .rovSafety) { (state: RovSafetyState) in
//            print(state)
//        }
//        FastRTPS.registerReader(topic: .rovImuCalibration) { (calibration: IMUCalibration) in
//            print(calibration)
//        }
//        FastRTPS.registerReader(topic: .rovDepthConfigCurrent) { (config: RovDepthConfig) in
//            print(config)
//        }
//        FastRTPS.registerReader(topic: .rovControllerStateCurrent) { (status: RovControllerStatus) in
//            print(status)
//        }

    }
}
