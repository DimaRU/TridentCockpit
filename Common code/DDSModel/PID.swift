/////
////  PID.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct PIDState: DDSKeyed {
   
    // The State of a PID Controller
    
    // The ID of the vehicle we are sending these parameters to
    let vehicleID: String //@key

    // The controller we are sending these parameters to
    // TODO: Should these be enumed out? String for now as we prototype
    let controllerID: String //@key

    // The output of each term
    let outputP: Float
    let outputI: Float
    let outputD: Float

    // The control output
    let controlEffort: Float

    // The integral term
    let integral: Float

    // Error terms
    let currentError: Float
    let previousError: Float
    
    var key: Data { (vehicleID+controllerID).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::PIDState" }
}

struct PIDParameters: DDSKeyed {
    // The ID of the vehicle we are sending these parameters to
    let vehicleID: String //@key

    // The controller we are sending these parameters to
    // TODO: Should these be enumed out? String for now as we prototype
    let controllerID: String //@key

    // The minimum control output
    let minControlOutput: Float
    
    // Max control output
    let maxControlOutput: Float

    // Terms
    let Kp: Float // Proportional term
    let Ki: Float // Integral term
    let Kd: Float // Derivative term

    // Integral windup limit
    let windupLimit: Float

    // Filter parameter for the input to the derivative block
    let shouldFilterInput: Bool
    let alpha: Float

    var key: Data { (vehicleID+controllerID).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::PIDParameters" }
}

struct PIDSetpoint: DDSKeyed {
    // The ID of the vehicle we are sending these parameters to
    let vehicleID: String //@key

    // The controller we are sending these parameters to
    // TODO: Should these be enumed out? String for now as we prototype
    let controllerID: String //@key

    // Should this controller be active?
    let enabled: Bool

    // The desired or current setpoint for this controller
    let setpoint: Float

    // The current process variable for this setpoint
    let processVariable: Float

    var key: Data { (vehicleID+controllerID).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::PIDSetpoint" }
}
