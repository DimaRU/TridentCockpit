/////
////  RovTopic.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

enum RovWriterTopic: String, DDSWriterTopic {
//    case rovAttitudeEuler            = "rov_attitude_euler"                // orov::msg::sensor::AttitudeEuler                [geoserve]
    case rovCamFwdH2640CtrlRequested = "rov_cam_fwd_H264_0_ctrl_requested" // orov::msg::image::ControlValue                  [geoserve]
    case rovCamFwdH2641CtrlRequested = "rov_cam_fwd_H264_1_ctrl_requested" // orov::msg::image::ControlValue                  [geoserve]
    case rovDatetime                 = "rov_datetime"                      // DDS::String                                     [geoserve]
//    case rovDepth                    = "rov_depth"                         // orov::msg::sensor::Depth                        [geoserve]
//    case rovTempWater                = "rov_temp_water"                    // orov::msg::sensor::Temperature                  [geoserve]
    case rovVideoOverlayModeCommand  = "rov_video_overlay_mode_command"    // DDS::String                                     [geoserve]
    case pidParametersRequested      = "pid_parameters_requested"          // orov::msg::control::PIDParameters               [trident-control]
    case pidSetpointRequested        = "pid_setpoint_requested"            // orov::msg::control::PIDSetpoint                 [trident-control]
//    case rovAttitudeEuler            = "rov_attitude_euler"                // orov::msg::sensor::AttitudeEuler                [trident-control]
    case rovControlTarget            = "rov_control_target"                // orov::msg::control::TridentControlTarget        [trident-control]
    case rovControllerStateRequested = "rov_controller_state_requested"    // orov::msg::control::ControllerStatus            [trident-control]
//    case rovDepth                    = "rov_depth"                         // orov::msg::sensor::Depth                        [trident-control]
    case rovMotorCommandDebug        = "rov_motor_command_debug"           // orov::msg::control::TridentMotorCommand         [trident-control]
    case tridentEscConfigRequest     = "trident_esc_config_request"        // orov::msg::control::TridentMotorConfigRequest   [trident-control]
    case rovLightPowerRequested      = "rov_light_power_requested"         // orov::msg::device::LightPower                   [trident-core]
    case rovPingRequest              = "rov_ping_request"                  // DDS::String                                     [trident-core]
    case rovVactestBlinkCommand      = "rov_vactest_blink_command"         // orov::msg::common::Command                      [trident-core]
    case tridentCommandTarget        = "trident_command_target"            // orov::msg::control::TridentMotorCommand         [trident-core]
    case tridentEscConfigTarget      = "trident_esc_config_target"         // orov::msg::control::TridentMotorConfig          [trident-core]
    case rovCamDwnH2640Video         = "rov_cam_dwn_H264_0_video"          // orov::msg::image::VideoData                     [trident-record]
    case rovCamFwdH2641Video         = "rov_cam_fwd_H264_1_video"          // orov::msg::image::VideoData                     [trident-record]
    case rovVidSessionReq            = "rov_vid_session_req"               // orov::msg::recording::VideoSessionCommand       [trident-record]
    case asvCommandSequence          = "asv_command_sequence"              // orov::msg::waypoint::TCommandList               [trident-remote-control]
    case asvSubsystemStatus          = "asv_subsystem_status"              // asv::msg::system::TASVSubsystemStatus           [trident-remote-control]
    case rovGpsStatus                = "rov_gps_status"                    // orov::msg::sensor::GPS                          [trident-remote-control]
//    case rovAttitudeEuler            = "rov_attitude_euler"                // orov::msg::sensor::AttitudeEuler                [trident-remote-control]
//    case rovControllerStateCurrent   = "rov_controller_state_current"      // orov::msg::control::ControllerStatus            [trident-remote-control]
//    case rovEscFaultAlert            = "rov_esc_fault_alert"               // orov::msg::control::ESCFaultAlert               [trident-remote-control]
//    case rovEscFaultWarningInfo      = "rov_esc_fault_warning_info"        // orov::msg::control::ESCFaultWarningInfo         [trident-remote-control]
//    case rovEscFeedback              = "rov_esc_feedback"                  // orov::msg::control::ESCFeedback                 [trident-remote-control]
//    case rovFuelgaugeStatus          = "rov_fuelgauge_status"              // orov::msg::sensor::FuelgaugeStatus              [trident-remote-control]
//    case rovLightPowerCurrent        = "rov_light_power_current"           // orov::msg::device::LightPower                   [trident-remote-control]
//    case rovMcuStatus                = "rov_mcu_status"                    // orov::msg::system::MCUStatus                    [trident-remote-control]
//    case rovPressureInternal         = "rov_pressure_internal"             // orov::msg::sensor::Barometer                    [trident-remote-control]
//    case rovSubsystemStatus          = "rov_subsystem_status"              // orov::msg::system::SubsystemStatus              [trident-remote-control]
//    case rovVidSessionRep            = "rov_vid_session_rep"               // orov::msg::recording::VideoSessionCommand       [trident-remote-control]
    case rovFirmwareCommandReq       = "rov_firmware_command_req"          // orov::msg::system::FirmwareCommand              [trident-update]
    case rovMcuStatus                = "rov_mcu_status"                    // orov::msg::system::MCUStatus                    [trident-update]
}

enum RovReaderTopic: String, DDSReaderTopic {
    case rovCamFwd                   = "rov_cam_fwd"                       // orov::msg::image::Channel                       [geoserve]
    case rovCamFwdH2640CtrlCurrent   = "rov_cam_fwd_H264_0_ctrl_current"   // orov::msg::image::ControlValue                  [geoserve]
    case rovCamFwdH2640CtrlDesc      = "rov_cam_fwd_H264_0_ctrl_desc"      // orov::msg::image::ControlDescriptor             [geoserve]
    case rovCamFwdH2640Video         = "rov_cam_fwd_H264_0_video"          // orov::msg::image::VideoData                     [geoserve]
    case rovCamFwdH2641CtrlCurrent   = "rov_cam_fwd_H264_1_ctrl_current"   // orov::msg::image::ControlValue                  [geoserve]
    case rovCamFwdH2641CtrlDesc      = "rov_cam_fwd_H264_1_ctrl_desc"      // orov::msg::image::ControlDescriptor             [geoserve]
    case rovCamFwdH2641Video         = "rov_cam_fwd_H264_1_video"          // orov::msg::image::VideoData                     [geoserve]
    case rovCams                     = "rov_cams"                          // orov::msg::image::Camera                        [geoserve]
    case rovVideoOverlayModeCurrent  = "rov_video_overlay_mode_current"    // DDS::String                                     [geoserve]
    case pidSetpointCurrent          = "pid_setpoint_current"              // orov::msg::control::PIDSetpoint                 [trident-control]
    case pidState                    = "pid_state"                         // orov::msg::control::PIDState                    [trident-control]
    case rovControllerStateCurrent   = "rov_controller_state_current"      // orov::msg::control::ControllerStatus            [trident-control]
    case rovSafety                   = "rov_safety"                        // orov::msg::control::SafetyState                 [trident-control]
//    case tridentCommandTarget        = "trident_command_target"            // orov::msg::control::TridentMotorCommand         [trident-control]
//    case tridentEscConfigTarget      = "trident_esc_config_target"         // orov::msg::control::TridentMotorConfig          [trident-control]
    case rovAttitude                 = "rov_attitude"                      // orov::msg::sensor::Attitude                     [trident-core]
    case rovAttitudeEuler            = "rov_attitude_euler"                // orov::msg::sensor::AttitudeEuler                [trident-core]
    case rovBeacon                   = "rov_beacon"                        // orov::msg::system::ROVBeacon                    [trident-core]
    case rovDepth                    = "rov_depth"                         // orov::msg::sensor::Depth                        [trident-core]
    case rovEscFaultAlert            = "rov_esc_fault_alert"               // orov::msg::control::ESCFaultAlert               [trident-core]
    case rovEscFaultWarningInfo      = "rov_esc_fault_warning_info"        // orov::msg::control::ESCFaultWarningInfo         [trident-core]
    case rovEscFeedback              = "rov_esc_feedback"                  // orov::msg::control::ESCFeedback                 [trident-core]
    case rovFuelgaugeHealth          = "rov_fuelgauge_health"              // orov::msg::sensor::FuelgaugeHealth              [trident-core]
    case rovFuelgaugeStatus          = "rov_fuelgauge_status"              // orov::msg::sensor::FuelgaugeStatus              [trident-core]
    case rovImuCalibration           = "rov_imu_calibration"               // orov::msg::system::IMUCalibration               [trident-core]
    case rovLightPowerCurrent        = "rov_light_power_current"           // orov::msg::device::LightPower                   [trident-core]
    case rovMcuCommStats             = "rov_mcu_comm_stats"                // orov::msg::system::CommStats                    [trident-core]
    case rovMcuI2cStats              = "rov_mcu_i2c_stats"                 // orov::msg::system::I2CStats                     [trident-core]
    case rovMcuStatus                = "rov_mcu_status"                    // orov::msg::system::MCUStatus                    [trident-core]
    case rovMcuWatchdogStatus        = "rov_mcu_watchdog_status"           // orov::msg::system::MCUWatchdogStatus            [trident-core]
    case rovPingReply                = "rov_ping_reply"                    // DDS::String                                     [trident-core]
    case rovPressureInternal         = "rov_pressure_internal"             // orov::msg::sensor::Barometer                    [trident-core]
    case rovSubsystemStatus          = "rov_subsystem_status"              // orov::msg::system::SubsystemStatus              [trident-core]
    case rovTempInternal             = "rov_temp_internal"                 // orov::msg::sensor::Temperature                  [trident-core]
    case rovTempWater                = "rov_temp_water"                    // orov::msg::sensor::Temperature                  [trident-core]
//    case tridentEscConfigRequest     = "trident_esc_config_request"        // orov::msg::control::TridentMotorConfigRequest   [trident-core]
    case rovRecordingStats           = "rov_recording_stats"               // orov::msg::recording::RecordingStats            [trident-record]
    case rovVidSessionCurrent        = "rov_vid_session_current"           // orov::msg::recording::VideoSession              [trident-record]
    case rovVidSessionRep            = "rov_vid_session_rep"               // orov::msg::recording::VideoSessionCommand       [trident-record]
//    case asvCommandSequence          = "asv_command_sequence"              // orov::msg::waypoint::TCommandList               [trident-remote-control]
//    case rovControlTarget            = "rov_control_target"                // orov::msg::control::TridentControlTarget        [trident-remote-control]
//    case rovLightPowerRequested      = "rov_light_power_requested"         // orov::msg::device::LightPower                   [trident-remote-control]
//    case rovModeSignal               = "rov_mode_signal"                   // asv::msg::system::TModeSignalMessage            [trident-remote-control]
//    case rovMotorCommandDebug        = "rov_motor_command_debug"           // orov::msg::control::TridentMotorCommand         [trident-remote-control]
//    case rovStateSignal              = "rov_state_signal"                  // asv::msg::system::TStateSignalMessage           [trident-remote-control]
//    case rovVactestBlinkCommand      = "rov_vactest_blink_command"         // orov::msg::common::Command                      [trident-remote-control]
//    case rovVidSessionReq            = "rov_vid_session_req"               // orov::msg::recording::VideoSessionCommand       [trident-remote-control]
    case rovFirmwareCommandRep       = "rov_firmware_command_rep"          // orov::msg::system::FirmwareCommand              [trident-update]
    case rovFirmwareServiceStatus    = "rov_firmware_service_status"       // orov::msg::system::FirmwareServiceStatus        [trident-update]
    case rovFirmwareStatus           = "rov_firmware_status"               // orov::msg::system::FirmwareStatus               [trident-update]
}

extension RovReaderTopic {
    var readerProfile: RTPSReaderProfile {
        .init(reliability: self.reliability, durability: self.durability)
    }
    var durability: Durability {
        switch self {
        case .rovCamFwd,
             .rovCamFwdH2640CtrlCurrent,
             .rovCamFwdH2640CtrlDesc,
             .rovCamFwdH2641CtrlCurrent,
             .rovCamFwdH2641CtrlDesc,
             .rovCams,
             .rovVideoOverlayModeCurrent,
             .rovSafety,
             .rovBeacon,
             .rovFuelgaugeHealth,
             .rovFuelgaugeStatus,
             .rovImuCalibration,
             .rovLightPowerCurrent,
             .rovMcuI2cStats,
             .rovSubsystemStatus,
             .rovRecordingStats,
             .rovVidSessionCurrent,
             .rovFirmwareServiceStatus,
             .rovFirmwareStatus:
            return .transientLocal
        default:
            return .volatile
         }
    }
    
    var reliability: Reliability {
        switch self {
        case .rovCamFwd,
             .rovCamFwdH2640CtrlCurrent,
             .rovCamFwdH2640CtrlDesc,
             .rovCamFwdH2640Video,
             .rovCamFwdH2641CtrlCurrent,
             .rovCamFwdH2641CtrlDesc,
             .rovCamFwdH2641Video,
             .rovCams,
             .rovVideoOverlayModeCurrent,
             .rovControllerStateCurrent,
             .rovSafety,
             .rovBeacon,
             .rovFuelgaugeHealth,
             .rovFuelgaugeStatus,
             .rovImuCalibration,
             .rovLightPowerCurrent,
             .rovMcuI2cStats,
             .rovSubsystemStatus,
             .rovRecordingStats,
             .rovVidSessionCurrent,
             .rovVidSessionRep,
             .rovFirmwareCommandRep,
             .rovFirmwareServiceStatus,
             .rovFirmwareStatus:
            return .reliable
        default:
            return .bestEffort
        }
    }
}

extension RovWriterTopic {
    var writerProfile: RTPSWriterProfile {
        .init(reliability: .reliable,
              durability: self.durability,
              disablePositiveACKs: true)
    }

    var durability: Durability {
        switch self {
        case .rovDatetime,
             .rovVideoOverlayModeCommand:
            return .transientLocal
        default:
            return .volatile
        }
    }
}
