/////
////  RovRecording.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

enum EVideoSessionCommandResponse: Int32, Codable {
    case unknown                   = 0
    case accepted                  = 1    // Session request was accepted
    case rejectedGeneric           = 2    // Placeholder for any rejection reason not listed below
    case rejectedSessionInProgress = 3    // There is already a recording in progress. Current session needs to be stopped.
    case rejectedInvalidSession    = 4    // There is no active session to be stopped with this ID
    case rejectedNoSpace           = 5    // There is not enough space to begin a new recording
}

enum EVideoSessionState: Int32, Codable {
    case unknown                   = 0
    case recording                 = 1     // Actively recording video
    case stopped                   = 2     // Recording stopped, either intentionally or due to an error while recording
}

enum EVideoSessionSubstate: Int32, Codable {
    case unknown                   = 0  // Initial state
    case stoppedProbing            = 1  // Recorder is waiting for an IDR frame to parse stream information
    case stoppedAligning           = 2  // Recorder is waiting for the next key frame
    case stoppedReady              = 3  // Recorder is ready to begin a recording session and is circulating one or more GOPs
    case recording                 = 4  // Recorder is actively recording frames to disk
    case stoppedError              = 5  // Error has occurred and must be dealt with (either recoverable or fatal)
    case stoppedTerminated         = 6  // Recording thread has terminated due to explicit termination signal or unexpected fatal error
}

enum EVideoSessionStopReason: Int32, Codable {
    case unknown                   = 0
    case clientRequest             = 1    // User explicitly requested recording stop
    case clientNotAlive            = 2    // There are no clients publishing to the session request topic (explicitly disconnected, crashed, extended network interruption)
    case videoSourceNotAlive       = 3    // There is no source of video data publishing on the topic being recorded (crashed, timed out, etc.)
    case filesystemNospace         = 4    // Ran out of space for video.
    case maxSessionSizeReached     = 5    // Reached the max configured byte size for a session and automatically stopped the recording.
    case recordingError            = 6    // An error occurred in the recording process (muxing, creating a file, etc)
}

enum EFilesystemProvisioningState: Int32, Codable {
    case unknown                   = 0
    case unprovisioned             = 1  // Filesystem has not been provisioned yet.
    case provisioned               = 2  // Filesystem for the recording subsystem has been successfully provisioned. See disk_space_total_bytes for size.
    case error                     = 3  // Filesystem can not be provisioned. See error_reason for more info
}

struct RovVideoSessionCommand: DDSUnkeyed {
    // Requester info
    let sessionID : String                 // If trying to stop a session, the ID should be provided here. If starting a session, leave blank. The vehicle will create the ID.
    let metadata  : String                 // Any additional information that should be associated with the recording if accepted (date/time, etc)
    let request   : EVideoSessionState     // Requested target state (recording or stopped)

    // Replier info
    let response  : EVideoSessionCommandResponse  // Contains the ACK/NACK response to the request
    let reason    : String                        // Additional NACK information

    static var ddsTypeName: String { "orov::msg::recording::VideoSessionCommand" }
}

struct RovVideoSession: DDSUnkeyed {
    let sessionID      : String                  // If trying to stop a session, the ID should be provided here. If starting a session, leave blank
    let metadata       : String                  // Any additional information that should be associated with the recording if accepted (date/time, etc)

    // Session state
    let state          : EVideoSessionState      // Current state of the session
    let stopReason     : EVideoSessionStopReason // If in STOPPED state, the last reason for stopping

    let segmentCount   : UInt32                 // Current number of segments in this session
    let totalDurationS : UInt32                 // Current total length of recording, rounded to seconds
    let totalSizeBytes : UInt64                 // Total disk space used by this session

    let substate       : EVideoSessionSubstate  // Current substate of the session

    static var ddsTypeName: String { "orov::msg::recording::VideoSession" }
}

struct RovRecordingStats: DDSKeyed {
    enum RecordingSubsystem: String, Codable {
        case video                 = "video"
        case telemetry             = "telemetry"
        case logs                  = "logs"
    }
    let recSubsysID          : RecordingSubsystem  //@key
    let diskSpaceTotalBytes  : UInt64              // Total space allocated for this subsystem
    let diskSpaceUsedBytes   : UInt64              // Space currently used up by subsystem
    let estRemainingRecTimeS : UInt32              // Estimate of remaining recording time available at current bandwidths

    let provisioningState    : EFilesystemProvisioningState
    let errorReason          : String

    var key: Data { recSubsysID.rawValue.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::recording::RecordingStats" }
}
