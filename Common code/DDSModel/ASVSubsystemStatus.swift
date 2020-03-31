/////
////  ASVSubsystemStatus.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

enum ESubsystemType: Int32, Codable {
    case navigator = 0
    case commander = 1
}

enum EState: Int32, Codable {
    case waiting   = 0
    case ready     = 1
    case traveling = 2
    case loitering = 3
    case stopped   = 4
    case paused    = 5
    case error     = 6
    case reset     = 7
}

enum EStateSignal: Int32, Codable {
    case waitSig   = 0
    case readySig  = 1
    case travelSig = 2
    case loiterSig = 3
    case stopSig   = 4
    case pauseSig  = 5
    case errorSig  = 6
    case resetSig  = 7
}

struct TStateMessage: Codable {
    let id: String //@key
    let state: EState
}

struct TStateSignalMessage: DDSKeyed {
    let id: String //@key
    let signal: EStateSignal

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "asv::msg::system::TStateSignalMessage" }
}


enum EMode: Int32, Codable {
    case none     = 0
    case auto     = 1
    case rtl      = 2
    case manual   = 3
    case behavior = 4
}

enum EModeSignal: Int32, Codable {
    case noneSig     = 0
    case autoSig     = 1
    case rtlSig      = 2
    case manualSig   = 3
    case behaviorSig = 4
}

struct TModeMessage: Codable {
    let id: String //@key
    let mode: EMode
}

struct TModeSignalMessage: DDSKeyed {
    let id: String //@key
    let signal: EModeSignal

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "asv::msg::system::TModeSignalMessage" }
}

struct TASVSubsystemStatus: DDSKeyed {
    let subsystemId: String //@key
    let type: ESubsystemType
    
    let state: EState
    let mode: EMode
    
    let stateSignal: EStateSignal
    let modeSignal: EModeSignal
    
    let target: Double    // Target heading in degrees
    let distance: Double  // Target distance in meters
    
    let waypointsProcessed: Bool
    let followingWaypoints: Bool
    let loitering: Bool
    let runHeadingController: Bool
    let runWaypointController: Bool
    let runLoiterController: Bool
    let moreWaypoints: Bool
    let nextWaypoint: Bool
    let waypointReached: Bool
    let waypointSet: Bool
    let waypointsReceived: Bool
    let threadNotified: Bool
    
    // TODO – mods for other FSM topologies (i.e. hierarchical)
    var key: Data { subsystemId.data(using: .utf8)! }
    static var ddsTypeName: String { "asv::msg::system::TASVSubsystemStatus" }
}

