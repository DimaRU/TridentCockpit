/////
////  RovChannel.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovChannel: DDSKeyed {
    // See V4L2 API for more details about fields
    struct RovPixelFormat: Codable {
        let pixelFormat: UInt32       //@key // FOURCC which specifies the exact pixel format
        let pixelFormatID: String     //@key // String representation of the pixel format, i.e. "H264"
        let width: UInt32
        let height: UInt32
        let field: UInt32
        let bytesPerLine: UInt32
        let sizeImage: UInt32
        let colorSpace: UInt8
        let priv: UInt32
        let flags: UInt32
        let ycbcrEnc: UInt8
        let hsvEnc: UInt8
        let quantization: UInt8
        let xferFunc: UInt8
    }
    let id: String              //@key
    let format: RovPixelFormat  //@key
    let extra: [String]

    var key: Data { id.data(using: .utf8)! }    // ????
    static var ddsTypeName: String { "orov::msg::image::Channel" }
}
