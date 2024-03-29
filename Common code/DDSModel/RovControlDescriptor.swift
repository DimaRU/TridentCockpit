/////
////  RovControlDescriptor.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

// Topic format: "<topicPrefix_rov_camChannels><channel_id>_ctrl_desc"
// Ex: rov_cam_forward_H2640_ctrl_desc
struct RovControlDescriptor: DDSKeyed {
    struct MenuOption: Codable {
        let valueString: String
        let valueS64: Int64
    }
    
    let id: UInt32       //@key
    let idString: String
    let type: UInt32
    let name: String
    let unit: String
    let minimum: Int64
    let maximum: Int64
    let step: UInt64
    let defaultValueNumeric: Int64
    let defaultValueString: String
    let flags: UInt32
    let menuOptions: [MenuOption]

    var key: Data { String(id).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::image::ControlDescriptor" }
}
