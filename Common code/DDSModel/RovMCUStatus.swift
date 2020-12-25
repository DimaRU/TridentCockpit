/////
////  RovMCUStatus.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct RovMCUStatus: DDSKeyed {
    // Trident MCU IDs
    enum tridentMCU: String, Codable {
        case mcuIDAll        = "!all"       // Special ID used to target all MCUs for commands like updates and resets
        case mcuIDSamd       = "samd21"
        case mcuIDPortEsc    = "port_esc"
        case mcuIDVertEsc    = "vert_esc"
        case mcuIDStarEsc    = "star_esc"
    }
    
    enum EMCUResetCause: Int32, Codable {
        case unknown        = 0
        case genericFault   = 1    // Placeholder for any type of fault not captured below
        case softReset      = 2    // Typically happens after flashing the chip. For ARM MCU's, corresponds generally to SysResetReq
        case watchdog       = 3
        case external       = 4    // Generally triggered by actuating a RESET pin
        case brownout       = 5    // Caused by one or more bus voltages dropping too low
        case powerOnReset   = 6    // Generally set after a normal power up sequence
    }
    
    
    enum EChecksumResult: Int32, Codable {
        case unknown = 0
        case waiting = 1
        case success = 2
        case failure = 3
    }
    
    
    let mcuID: String //@key
    
    let crcResult: EChecksumResult  // Result of the firmware CRC healthcheck (comparing CRC of current flash memory against compiled binary)
    let resetCause: EMCUResetCause  // Primary category of reset cause
    let resetExtra: UInt16          // Additional optional information about the reset event
    let uptimeSecs: UInt32          // Length of time that the chip has been powered (should be treated as approximate. All clocks differ!)
    
    let mavlinkVersion: UInt8       // Version of the OpenROV mavlink protocol being used by the MCU. Can be used to prevent invalid comms.
    
    let version: String             // Version information of the app running. Primary information used to perform Update checks.
    let appID: String               // Name of the app running. SAMD21 Ex: "trident" vs "battery_flasher" vs "empty"
    let boardID: String             // Product ID of the board the firmware was targeted for. Ex: "000001-02" for Trident Mainboard v2
    
    var key: Data { mcuID.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::MCUStatus" }
}

struct RovMCUWatchdogStatus: DDSKeyed {
    // ID of the system reporting the stats
    let id: String //@key

    let watchdog_early_warning_count: UInt32
    let watchdog_trigger_count: UInt32

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::MCUWatchdogStatus" }
}
