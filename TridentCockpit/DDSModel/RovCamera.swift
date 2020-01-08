/////
////  RovCamera.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovCamera: DDSKeyed
{
    let guid: String     //@key // Globally unique identifier within the domain/partition for a particular camera
    let driver: String   //@key // Name of the driver used by the camera, i.e. uvcvideo, gc6500, etc
    let card: String     //@key // Name of the device, i.e. orov_hd_pro_cam
    let bus_info: String //@key // Location of the device in the system, i.e. 'usb1/1-2'
    
    let version: UInt32         // Version of the driver
    let capabilities: UInt32    // Capabilities, as defined in the constants section above
    let reserved: [Int32]       // Additional reserved fields for V4L2-like devices. Not currently used.
    let extra: [String]         // Any additional, custom meta-data. i.e. gc6500 histogram or motion vector support
    let frame_id: String        // ID of the frame of reference associated with this camera
    let channel_ids: [String]   // List of channel IDs for this camera. Use these to find channel specific topics for this camera.
    
    var key: Data { (guid+driver+card+bus_info).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::image::Camera" }

}
