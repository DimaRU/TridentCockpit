/////
////  MaintenanceViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

class MaintenanceViewController: NSViewController {
    @IBOutlet weak var batteryChargeLabel: NSTextField!
    @IBOutlet weak var internalPressureLabel: NSTextField!
    @IBOutlet weak var internalTemperatureLabel: NSTextField!
    @IBOutlet weak var pressureLabel: NSTextField!
    @IBOutlet weak var temperatureLabel: NSTextField!

    private var pressure: Double = 0 {
        didSet { pressureLabel.stringValue = String(format: "%.3fkPa", pressure) }
    }
    private var internalPressure: Double = 0 {
        didSet { internalTemperatureLabel.stringValue = String(format: "%.3fkPa", internalPressure) }
    }
    private var temperature: Double = 0 {
        didSet { temperatureLabel.stringValue = String(format: "%.1f℃", temperature) }
    }
    private var internalTemperature: Double = 0 {
        didSet { internalTemperatureLabel.stringValue = String(format: "%.1f℃", internalTemperature) }
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
                self?.pressure = depth.pressure.fluidPressure
            }
        }

        FastRTPS.registerReader(topic: .rovTempInternal) { [weak self] (temp: RovTemperature) in
            DispatchQueue.main.async {
                self?.temperature = temp.temperature.temperature
            }
        }

        FastRTPS.registerReader(topic: .rovPressureInternal) { [weak self] (baro: RovBarometer) in
            DispatchQueue.main.async {
                self?.pressure = baro.pressure.fluidPressure
            }
        }

        FastRTPS.registerReader(topic: .rovFuelgaugeHealth) { [weak self] (health: RovFuelgaugeHealth) in
            DispatchQueue.main.async {
                self?.batteryChargeLabel.stringValue = "\(health.state.percentage)%"
            }
        }

    }
}
