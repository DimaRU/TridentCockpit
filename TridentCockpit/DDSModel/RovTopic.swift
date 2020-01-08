/////
////  RovTopic.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

enum RovWriterTopic: String {
    case pidParametersRequested      = "pid_parameters_requested" // orov::msg::control::PIDParameters
    case pidSetpointRequested        = "pid_setpoint_requested" // orov::msg::control::PIDSetpoint
    case rovCamFwdH2640CtrlRequested = "rov_cam_fwd_H264_0_ctrl_requested" // orov::msg::image::ControlValue
    case rovCamFwdH2641CtrlRequested = "rov_cam_fwd_H264_1_ctrl_requested" // orov::msg::image::ControlValue
    case rovCamFwdH2641Video         = "rov_cam_fwd_H264_1_video" // orov::msg::image::VideoData
    case rovControlTarget            = "rov_control_target" // orov::msg::control::TridentControlTarget
    case rovControllerStateRequested = "rov_controller_state_requested" // orov::msg::control::ControllerStatus
    case rovDatetime                 = "rov_datetime" // DDS::String
    case rovFirmwareCommandReq       = "rov_firmware_command_req" // orov::msg::system::FirmwareCommand
    case rovLightPowerRequested      = "rov_light_power_requested" // orov::msg::device::LightPower
    case rovMcuStatus                = "rov_mcu_status" // orov::msg::system::MCUStatus
    case rovMotorCommandDebug        = "rov_motor_command_debug" // orov::msg::control::TridentMotorCommand
    case rovPingRequest              = "rov_ping_request" // DDS::String
    case rovVactestBlinkCommand      = "rov_vactest_blink_command" // orov::msg::common::Command
    case rovVidSessionReq            = "rov_vid_session_req" // orov::msg::recording::VideoSessionCommand
    case rovVideoOverlayModeCommand  = "rov_video_overlay_mode_command" // DDS::String
    case tridentCommandTarget        = "trident_command_target" // orov::msg::control::TridentMotorCommand
    case navTrackingTarget           = "nav_tracking_target" // orov::msg::image::CameraObjectTrack
    case rovDepthConfigRequested     = "rov_depth_config_requested" // orov::msg::sensor::DepthConfig
}

enum RovReaderTopic: String {
    case pidSetpointCurrent         = "pid_setpoint_current" // orov::msg::control::PIDSetpoint
    case pidState                   = "pid_state" // orov::msg::control::PIDState
    case rovAttitude                = "rov_attitude" // orov::msg::sensor::Attitude
    case rovBeacon                  = "rov_beacon" // orov::msg::system::ROVBeacon
    case rovCamFwd                  = "rov_cam_fwd" // orov::msg::image::Channel
    case rovCamFwdH2640CtrlCurrent  = "rov_cam_fwd_H264_0_ctrl_current" // orov::msg::image::ControlValue
    case rovCamFwdH2640CtrlDesc     = "rov_cam_fwd_H264_0_ctrl_desc" // orov::msg::image::ControlDescriptor
    case rovCamFwdH2640Video        = "rov_cam_fwd_H264_0_video" // orov::msg::image::VideoData
    case rovCamFwdH2641CtrlCurrent  = "rov_cam_fwd_H264_1_ctrl_current" // orov::msg::image::ControlValue
    case rovCamFwdH2641CtrlDesc     = "rov_cam_fwd_H264_1_ctrl_desc" // orov::msg::image::ControlDescriptor
    case rovCamFwdH2641Video        = "rov_cam_fwd_H264_1_video" // orov::msg::image::VideoData
    case rovCams                    = "rov_cams" // orov::msg::image::Camera
    case rovControllerStateCurrent  = "rov_controller_state_current" // orov::msg::control::ControllerStatus
    case rovDepth                   = "rov_depth" // orov::msg::sensor::Depth
    case rovEscFaultAlert           = "rov_esc_fault_alert" // orov::msg::control::ESCFaultAlert
    case rovEscFaultWarningInfo     = "rov_esc_fault_warning_info" // orov::msg::control::ESCFaultWarningInfo
    case rovEscFeedback             = "rov_esc_feedback" // orov::msg::control::ESCFeedback
    case rovFirmwareCommandRep      = "rov_firmware_command_rep" // orov::msg::system::FirmwareCommand
    case rovFirmwareServiceStatus   = "rov_firmware_service_status" // orov::msg::system::FirmwareServiceStatus
    case rovFirmwareStatus          = "rov_firmware_status" // orov::msg::system::FirmwareStatus
    case rovFuelgaugeHealth         = "rov_fuelgauge_health" // orov::msg::sensor::FuelgaugeHealth
    case rovFuelgaugeStatus         = "rov_fuelgauge_status" // orov::msg::sensor::FuelgaugeStatus
    case rovImuCalibration          = "rov_imu_calibration" // orov::msg::system::IMUCalibration
    case rovLightPowerCurrent       = "rov_light_power_current" // orov::msg::device::LightPower
    case rovMcuCommStats            = "rov_mcu_comm_stats" // orov::msg::system::CommStats
    case rovMcuI2cStats             = "rov_mcu_i2c_stats" // orov::msg::system::I2CStats
    case rovMcuStatus               = "rov_mcu_status" // orov::msg::system::MCUStatus
    case rovMcuWatchdogStatus       = "rov_mcu_watchdog_status" // orov::msg::system::MCUWatchdogStatus
    case rovPingReply               = "rov_ping_reply" // DDS::String
    case rovPressureInternal        = "rov_pressure_internal" // orov::msg::sensor::Barometer
    case rovRecordingStats          = "rov_recording_stats" // orov::msg::recording::RecordingStats
    case rovSafety                  = "rov_safety" // orov::msg::control::SafetyState
    case rovSubsystemStatus         = "rov_subsystem_status" // orov::msg::system::SubsystemStatus
    case rovTempInternal            = "rov_temp_internal" // orov::msg::sensor::Temperature
    case rovTempWater               = "rov_temp_water" // orov::msg::sensor::Temperature
    case rovVidSessionCurrent       = "rov_vid_session_current" // orov::msg::recording::VideoSession
    case rovVidSessionRep           = "rov_vid_session_rep" // orov::msg::recording::VideoSessionCommand
    case rovVideoOverlayModeCurrent = "rov_video_overlay_mode_current" // DDS::String
    case tridentCommandTarget       = "trident_command_target" // orov::msg::control::TridentMotorCommand
    case mcuI2cStats                = "mcu_i2c_stats" // orov::msg::system::I2CStats
    case navTrackingCurrent         = "nav_tracking_current" // orov::msg::image::CameraObjectTrack
    case rovControlCurrent          = "rov_control_current" // orov::msg::control::TridentControlTarget
    case rovDepthConfigCurrent      = "rov_depth_config_current" // orov::msg::sensor::DepthConfig
}
