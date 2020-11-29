/////
////  RovSafetyState.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

enum ESafetyState: Int32, Codable {
    case off = 0 //Safety is off, controllers are running
    case on  = 1 // Safety is on, controllers have stopped
}

struct RovSafetyState: DDSKeyed {
    let vehicleId: String //@key
    let state: ESafetyState // State of the safety switch

    var key: Data { vehicleId.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::SafetyState" }
}
