/////
////  TridentDrive.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import Carbon.HIToolbox
import FastRTPSBridge

final class TridentDrive {
    private var leftLever: Float = 0
    private var rightLever: Float = 0
    private var forwardLever: Float = 0
    private var backwardLever: Float = 0
    private var upLever: Float = 0
    private var downLever: Float = 0
    private var tridentCommandTimer: Timer?
    private var zeroCount = 0

    func start() {
        tridentCommandTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            let thrust = self.forwardLever - self.backwardLever
            let yaw = self.rightLever - self.leftLever
            let pitch = self.downLever - self.upLever
            
            if (thrust, yaw, pitch) == (0, 0, 0) {
                self.zeroCount += 1
            } else {
                self.zeroCount = 0
            }
            if self.zeroCount >= 2 {
                return
            }
            let tridentCommand = RovTridentControlTarget(id: "control", pitch: pitch, yaw: yaw, thrust: thrust, lift: 0)
            FastRTPS.send(topic: .rovControlTarget, ddsData: tridentCommand)
        }
    }
    
    func stop() {
        tridentCommandTimer?.invalidate()
    }
    
    func processKeyEvent(event: NSEvent) -> Bool {
        var lever: Float = 0.1
        if NSEvent.modifierFlags.contains(.option) { lever = 0.25 }
        if NSEvent.modifierFlags.contains(.control) { lever = 0.50 }
        if NSEvent.modifierFlags.contains(.shift) { lever = 1 }

        if event.type == .keyDown {
            switch event.specialKey {
            case .upArrow?:
                forwardLever = lever
                backwardLever = 0
            case .downArrow?:
                backwardLever = lever
                forwardLever = 0
            case .leftArrow?:
                leftLever = lever
                rightLever = 0
            case .rightArrow?:
                rightLever = lever
                leftLever = 0
            default:
                switch Int(event.keyCode) {
                case kVK_ANSI_W:
                    upLever = lever
                    downLever = 0
                case kVK_ANSI_S:
                    downLever = lever
                    upLever = 0
                default:
                    return false
                }
            }
        }
        
        if event.type == .keyUp {
            switch event.specialKey {
            case .upArrow?:
                forwardLever = 0
            case .downArrow?:
                backwardLever = 0
            case .leftArrow?:
                leftLever = 0
            case .rightArrow?:
                rightLever = 0
            default:
                switch Int(event.keyCode) {
                case kVK_ANSI_W:
                    upLever = 0
                case kVK_ANSI_S:
                    downLever = 0
                default:
                    return false
                }
            }
        }
        return true
    }

}
