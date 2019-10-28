/////
////  RovFirmware.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

enum EFirmwareCommandType: Int32, Codable {
    case unknown         = 0
    case update          = 1    // Performs an update/repair if necessary
    case forcedUpdate    = 2    // Forces an update of the firmware
}

enum EFirmwareCommandResponse: Int32, Codable {
    case unknown                 = 0
    case accepted                = 1    // Update request was accepted
    case rejectedGeneric         = 2    // Placeholder for any rejection reason not listed below
    case rejectedInvalid         = 3    // Request was invalid (probably a bad MCU ID)
    case rejectedUnsupported     = 4    // Command was not supported
    case rejectedBusy            = 5    // MCU operation is already in progress
    case rejectedBadState        = 6     // System can not currently handle update requests due to some error (low power)
}

// Firmware service high-level state-machine states
enum EFirmwareServiceState: Int32, Codable {
    case unknown         = 0
    case initializing    = 1    // Service is starting up
    case checkingHealth  = 2    // Service is checking to see if updates/repairs are required
    case ready           = 3    // Service is ready to receive commands (see EFirmwareServiceCheckResult to determine if action required)
    case executing       = 4     // Service is performing updates/repairs
}

// Status that indicates whether or not updates/repairs are required
// This + Individual EFirmwareState info should inform client application about what to do
enum EFirmwareServiceCheckResult: Int32, Codable {
    case unknown         = 0    // Check has not yet been performed or completed
    case ok              = 1    // No updates or repairs required
    case actionRequired  = 2    // Update or repair is required. See individual EFirmwareState messages for details on each MCU
    case error           = 3     // An error has occurred. System should probably be recovered/restarted
}

enum EFirmwareState: Int32, Codable {
    case unknown             = 0
    case checkingHealth      = 1    // Version/CRC check in progress
    case ok                  = 2    // No updates or repairs required
    case updateRequired      = 3    // Update or repair is required. See EFirmwareHealthCheck for reason
    case updatePending       = 4    // Update is pending
    case updateInProgress    = 5    // Update is currently underway
    case updateComplete      = 6    // Update operation completed
    case updateError         = 7     // Update failed. See reason string
}

enum EFirmwareHealthCheckResult: Int32, Codable {
    case unknown             = 0    // Check has not been performed
    case ok                  = 1    // Firmware is verified as up-to-date and not corrupt
    case firmwareMismatch    = 2    // Firmware version/board/app information did not match the current designated firmware
    case checksumMismatch    = 3    // Internal CRC Checksum of device's firmware failed. Considered corrupted.
    case unresponsive        = 4     // No telemetry received from device. Could have no firmware corrupted etc.
}

struct RovFirmwareCommand: DDSKeyed {
    let targetMCUID: String                 //@key

    // Requester parameters
    let command: EFirmwareCommandType

    // Replier parameters
    let response: EFirmwareCommandResponse  // Contains the ACK/NACK response to the request
    let reason: String                      // Additional NACK information

    var key: Data { targetMCUID.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::FirmwareCommand" }
}

struct RovFirmwareServiceStatus: DDSUnkeyed {
    let state: EFirmwareServiceState                // Current state of the firmware service
    let check_result: EFirmwareServiceCheckResult   // Result of performing all firmware checks
    let errorInfo: String                           // Additional optional information about any errors

    static var ddsTypeName: String { "orov::msg::system::FirmwareServiceStatus" }
}

struct RovFirmwareStatus: DDSKeyed {
    let mcuID: String //@key

    let state: EFirmwareState                       // Current state of the firmware update process for the specified MCU
    let check_result: EFirmwareHealthCheckResult    // Result of the firmware health check for the specified MCU
    let checkInfo: String                           // Additional information about the health check

    let currentVersion: String
    let currentAppID: String
    let currentBoardID: String

    let targetVersion: String
    let targetAppID: String
    let targetBoardID: String

    var key: Data { mcuID.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::FirmwareStatus" }
}
