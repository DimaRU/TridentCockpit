/////
////  RovWaypoint.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct TWaypoint: Codable {
    let lat: Double
    let lon: Double
}

// Simple waypoint navigation
struct TWaypoints: Codable {
    let id: String //@key
    let waypoints: [TWaypoint]
}

// Complex waypoint/behavior handling

enum TAction: Int32, Codable {
    case none       = 0
    case videoOn    = 1
    case videoOff   = 2
    case dive       = 3
    case pause      = 4
    case loiter     = 5
    case stop       = 6
    case rotate     = 7
    case `continue` = 8
    case rtl        = 9
}

enum TParameter: Int32, Codable {
    case none       = 0
    case timerSec   = 1
    case timerCont  = 2
    case distance   = 3
    case rotation   = 4
}

struct TCommand: Codable {
    let action: TAction
    let paramType: TParameter
    // Depending upon action, timer, distance, rotation or ignored
    let parameter: Double
    let mode: EMode
}

struct TWaypointCommand: Codable {
    let waypoint: TWaypoint
    let commands: [TCommand]
}

struct TCommandList: DDSUnkeyed {
    let list: [TWaypointCommand]
    
    static var ddsTypeName: String { "orov::msg::waypoint::TCommandList" }
}

