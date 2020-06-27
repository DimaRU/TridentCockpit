/////
////  MaintenanceViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import PromiseKit
import Moya

class MaintenanceViewController: UIViewController, StoryboardInstantiable {
    @IBOutlet weak var batteryChargeLabel: UILabel!
    @IBOutlet weak var batteryCycleLabel: UILabel!
    @IBOutlet weak var internalPressureLabel: UILabel!
    @IBOutlet weak var internalTemperatureLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var connectionAddress: UILabel!
    @IBOutlet weak var localAddressLabel: UILabel!
    @IBOutlet weak var networkAddressLabel: UILabel!

    @Average(10) private var pressure: Double
    @Average(10) private var temperature: Double

    private var internalPressure: Double = 0 {
        didSet {
            DispatchQueue.main.async {
                self.internalPressureLabel.text = String(format: "%.3f", self.internalPressure)
            }
        }
    }
    private var internalTemperature: Double = 0 {
        didSet {
            DispatchQueue.main.async {
                self.internalTemperatureLabel.text = String(format: "%.2f", self.internalTemperature)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        batteryChargeLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        batteryCycleLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        internalPressureLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        internalTemperatureLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        pressureLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        temperatureLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        
        batteryChargeLabel.text = ""
        batteryCycleLabel.text = ""
        internalPressureLabel.text = ""
        internalTemperatureLabel.text = ""
        pressureLabel.text = ""
        temperatureLabel.text = ""
        networkAddressLabel.text = ""
        
        configurAverage()
        registerReaders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        connectionAddress.text = FastRTPS.remoteAddress
        localAddressLabel.text = FastRTPS.localAddress
        
        RestProvider.request(MultiTarget(ResinAPI.deviceState))
        .done { (deviceState: DeviceState) in
            self.networkAddressLabel.text = (deviceState.ipAddress ?? "n/a").replacingOccurrences(of: " ", with: ", ")
        }.catch { _ in
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FastRTPS.resignAll()
    }
    
    @IBAction func closeButtonPress(_ sender: Any) {
        FastRTPS.resignAll()
        dismiss(animated: true)
    }
    
    private func configurAverage() {
        _pressure.configure { [weak self] avg in
            DispatchQueue.main.async {
                self?.pressureLabel.text = String(format: "%.3f", avg)
            }
        }
        _temperature.configure { [weak self] avg in
            DispatchQueue.main.async {
                self?.temperatureLabel.text = String(format: "%.2f", avg)
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
                self?.batteryChargeLabel.text = String(format: "%.0f%%", status.state.percentage * 100)
            }
        }

        FastRTPS.registerReader(topic: .rovFuelgaugeHealth) { [weak self] (health: RovFuelgaugeHealth) in
            DispatchQueue.main.async {
                self?.batteryCycleLabel.text = String(health.cycle_count)
            }
        }

        #if ROVDEBUG
        FastRTPS.registerReader(topic: .rovCamFwd) { (channel: RovChannel) in
            print(channel)
        }

        FastRTPS.registerReader(topic: .rovCams) { (camera: RovCamera) in
            print(camera)
        }

        FastRTPS.registerReader(topic: .rovCamFwdH2640CtrlDesc) { (descriptor: RovControlDescriptor) in
            print("H264_0", descriptor)
        }

        FastRTPS.registerReader(topic: .rovCamFwdH2641CtrlDesc) { (descriptor: RovControlDescriptor) in
            print("H264_1", descriptor)
        }

        FastRTPS.registerReader(topic: .rovSubsystemStatus) { (status: RovSubsystemStatus) in
            print("status:", status.subsystemId.rawValue, status.substate)
        }
        FastRTPS.registerReader(topic: .rovFirmwareStatus) { (firmwareStatus: RovFirmwareStatus) in
            print(firmwareStatus)
        }
        FastRTPS.registerReader(topic: .rovFirmwareServiceStatus) { (firmwareServiceStatus: RovFirmwareServiceStatus) in
            print(firmwareServiceStatus)
        }
        FastRTPS.registerReader(topic: .rovFirmwareCommandRep) { (command: RovFirmwareCommand) in
            print(command)
        }
        FastRTPS.registerReader(topic: .rovControlCurrent) { (control: RovTridentControlTarget) in
            print(control)
        }
        FastRTPS.registerReader(topic: .navTrackingCurrent) { (cameraObjectTrack: RovCameraObjectTrack) in
            print(cameraObjectTrack)
        }
        FastRTPS.registerReader(topic: .mcuI2cStats) { (stats: I2CStats) in
            print(stats)
        }
        FastRTPS.registerReader(topic: .rovSafety) { (state: RovSafetyState) in
            print(state)
        }
        FastRTPS.registerReader(topic: .rovImuCalibration) { (calibration: IMUCalibration) in
            print(calibration)
        }
        FastRTPS.registerReader(topic: .rovDepthConfigCurrent) { (config: RovDepthConfig) in
            print(config)
        }
        FastRTPS.registerReader(topic: .rovControllerStateCurrent) { (status: RovControllerStatus) in
            print(status)
        }
        #endif

    }
}
