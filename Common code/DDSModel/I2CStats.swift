/////
////  I2CStats.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct I2CStats: DDSKeyed {
    // ID of the MCU reporting the stats
    let id: String                         //@key

    let recoveryCount: UInt32       // How many times any form of recovery is attempted
    let hardResetCount: UInt32      // Count of hard bus resets (bus power cycle)
    let softResetCount: UInt32      // Count of soft bus resets (logic/driver based recovery)
    let limitBreakCount: UInt32     // Count of failure limits reached across all devices on system
    let busFailureCount: UInt32     // Count of peripheral bus failures
    let latchFailureCount: UInt32   // Count of failures caused by a latched bus

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::I2CStats" }
}
