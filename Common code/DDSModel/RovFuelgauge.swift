/////
////  RovFuelgauge.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct RovFuelgaugeStatus: DDSKeyed {
    let state: BatteryState

    let id: String //@key
    let averageCurrent: Float
    let averagePower: Float
    let batteryTemperature: Float

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::sensor::FuelgaugeStatus" }
}

struct RovFuelgaugeHealth: DDSKeyed {
    let state: BatteryState

    let id: String //@key
    let full_charge_capacity: Float
    let average_time_to_empty_mins: Int32
    let cycle_count: Int32
    let state_of_health_pct: Float

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::sensor::FuelgaugeHealth" }
}
