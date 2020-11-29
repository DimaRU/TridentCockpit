/////
////  RovTridentControlTarget.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

// High-level control commands issued by a user or other high-level control system. Units vary depending on current control mode.
// E.g., pitch could be a target position in rads, while yaw is a target yaw rate in rads/sec
struct RovTridentControlTarget: DDSKeyed
{
    let id: String //@key

    let pitch: Float
    let yaw: Float
    let thrust: Float
    let lift: Float

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::TridentControlTarget" }
}
