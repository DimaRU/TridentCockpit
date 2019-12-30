/////
////  MaintenanceViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

class MaintenanceViewController: NSViewController {
    @IBOutlet weak var batteryChargeLabel: NSTextField!
    @IBOutlet weak var batteryCycleLabel: NSTextField!
    @IBOutlet weak var internalPressureLabel: NSTextField!
    @IBOutlet weak var internalTemperatureLabel: NSTextField!
    @IBOutlet weak var pressureLabel: NSTextField!
    @IBOutlet weak var temperatureLabel: NSTextField!
    
    private var pressure: Double = 0 {
        didSet { pressureLabel.stringValue = String(format: "%.3f kPa", pressure) }
    }
    private var internalPressure: Double = 0 {
        didSet { internalPressureLabel.stringValue = String(format: "%.3f kPa", internalPressure) }
    }
    private var temperature: Double = 0 {
        didSet { temperatureLabel.stringValue = String(format: "%.2f", temperature) }
    }
    private var internalTemperature: Double = 0 {
        didSet { internalTemperatureLabel.stringValue = String(format: "%.2f", internalTemperature) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerReaders()
    }

    @IBAction func closeButtonPress(_ sender: Any) {
        FastRTPS.resignAll()
        dismiss(sender)
    }

    private func registerReaders() {
        FastRTPS.registerReader(topic: .rovTempWater) { [weak self] (temp: RovTemperature) in
            DispatchQueue.main.async {
                self?.temperature = temp.temperature.temperature
            }
        }

        FastRTPS.registerReader(topic: .rovDepth) { [weak self] (depth: RovDepth) in
            DispatchQueue.main.async {
                self?.pressure = depth.pressure.fluidPressure / 10
            }
        }

        FastRTPS.registerReader(topic: .rovTempInternal) { [weak self] (temp: RovTemperature) in
            DispatchQueue.main.async {
                self?.internalTemperature = temp.temperature.temperature
            }
        }

        FastRTPS.registerReader(topic: .rovPressureInternal) { [weak self] (baro: RovBarometer) in
            DispatchQueue.main.async {
                self?.internalPressure = baro.pressure.fluidPressure / 10
            }
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
//        FastRTPS.registerReader(topic: .rovAttitude) { (attitude: RovAttitude) in
//            print(attitude)
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
