/////
////  RovVideoData.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge


//const unsigned long VIDEO_DATA_MAX_SIZE = 1000 * 1024;           // 1MB
//const unsigned long IMAGE_DATA_MAX_SIZE = 12 * 1024 * 1024;     // 12MB

struct RovVideoData: DDSUnkeyed {
    let timestamp: UInt64
    let frame_id: UInt64
    let data: Data

    static var ddsTypeName: String { "orov::msg::image::VideoData" }
}

// Topic format: "<topicPrefix_rov_camChannels><channel_id>_ctrl_video"
// Ex: rov_cam_forward_H2640_video
//struct RovImageData: Codable {
//    let timestamp: UInt64
//    let frame_id: UInt64
//    let data: Data
//}

struct RovVideoStats: Codable {
    let average_bitrate: UInt32        // Average calculated bitrate
    let min_frame_size: UInt32         // Smallest frame seen
    let max_frame_size: UInt32         // Largest frame seen
    let dropped_frames: UInt32         // Number of frames not even sent to readers, usually due to slow servicing of the camera or frame queues
    let lost_frames: UInt32            // Number of frames lost between the reader and writer. Usually due to poor connection
    let est_camera_latency: UInt32     // Estimated latency component due to the camera's processing pipeline
    let est_processing_latency: UInt32 // Estimated latency component due to server software that moves data from camera to reader
    let est_network_latency: UInt32    // Estimated latency component due to transmission over the network, which includes reliability protocol and things like wifi retry
    let est_total_latency: UInt32      // Estimated total latency, sum of above
    let fps: Float                     // Calculated FPS, based on timestamps received directly from camera
}
