/////
////  TridentControl.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

#if os(macOS)
import Cocoa
import Carbon.HIToolbox
#endif
import GameController

protocol TridentControlDelegate: NSObject {
    func updatePropellerButtonState()
    func switchLight()
    func switchRecording()
    func switchAuxRecording()
    func switchAuxPower()
    func control(pitch: Float, yaw: Float, thrust: Float, lift: Float)
}

final class TridentControl {
    enum MotorSpeed: Int {
        case first, second, third
        var rate: Float {
            switch self {
            case .first:  return 0.2
            case .second: return 0.4
            case .third:  return 1
            }
        }
    }
    private var leftLever: Float = 0
    private var rightLever: Float = 0
    private var forwardLever: Float = 0
    private var backwardLever: Float = 0
    private var upLever: Float = 0
    private var downLever: Float = 0
    private var tridentCommandTimer: Timer?
    private var zeroCount = 0
    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?

    
    private weak var delegate: TridentControlDelegate?
    var motorSpeed: MotorSpeed?

    func setup(delegate: TridentControlDelegate) {
        self.delegate = delegate
        connectGameController()
        ObserveForGameControllers()
    }
    
    func enable() {
        tridentCommandTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: controlTimerBlock)
    }
    
    func disable() {
        tridentCommandTimer?.invalidate()
        
        if let connectObserver = connectObserver {
            NotificationCenter.default.removeObserver(connectObserver)
        }
        if let disconnectObserver = disconnectObserver {
            NotificationCenter.default.removeObserver(disconnectObserver)
        }
        connectObserver = nil
        disconnectObserver = nil
    }
    
    private func controlTimerBlock(timer: Timer) {
        let thrust = forwardLever - backwardLever
        let yaw = rightLever - leftLever
        let pitch = downLever - upLever
        
        if (thrust, yaw, pitch) == (0, 0, 0) {
            zeroCount += 1
        } else {
            zeroCount = 0
        }
        if zeroCount >= 2 {
            return
        }
        delegate?.control(pitch: pitch, yaw: yaw, thrust: thrust, lift: 0)
    }
    
#if os(macOS)
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
#endif
    
    func ObserveForGameControllers() {
        connectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { _ in
            self.connectGameController()
        }
        
        disconnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { _ in
            self.motorSpeed = nil
            self.delegate?.updatePropellerButtonState()
        }
    }
    
    private func connectGameController() {
        var indexNumber = 0
        for controller in GCController.controllers() {
            if controller.extendedGamepad != nil {
                if #available(OSX 10.15, *) {
                    print(controller.productCategory)
                }
                controller.playerIndex = GCControllerPlayerIndex(rawValue: indexNumber)!
                indexNumber += 1
                if self.motorSpeed == nil {
                    self.motorSpeed = .first
                    self.delegate?.updatePropellerButtonState()
                }
                controller.extendedGamepad!.valueChangedHandler = { [weak self] (gamepad: GCExtendedGamepad, element: GCControllerElement) in
                    self?.controllerInputDetected(gamepad: gamepad, element: element, index: controller.playerIndex.rawValue)
                }
            }
        }
    }
    
    private func controllerInputDetected(gamepad: GCExtendedGamepad, element: GCControllerElement, index: Int) {
        switch element {
        case gamepad.leftThumbstick:
            forwardLever = gamepad.leftThumbstick.yAxis.value * motorSpeed!.rate
            backwardLever = 0
        case gamepad.rightThumbstick:
            rightLever = gamepad.rightThumbstick.xAxis.value * motorSpeed!.rate
            leftLever = 0
            downLever = gamepad.rightThumbstick.yAxis.value * motorSpeed!.rate
            upLever = 0
        case gamepad.leftShoulder:
            guard gamepad.leftShoulder.value != 0 else { break }
            guard motorSpeed != .first else { break }
            motorSpeed = MotorSpeed(rawValue: motorSpeed!.rawValue - 1)
            self.delegate?.updatePropellerButtonState()
        case gamepad.rightShoulder:
            guard gamepad.rightShoulder.value != 0 else { break }
            guard motorSpeed != .third else { break }
            motorSpeed = MotorSpeed(rawValue: motorSpeed!.rawValue + 1)
            self.delegate?.updatePropellerButtonState()
        case gamepad.buttonA:
            guard gamepad.buttonA.value != 0 else { break }
            delegate?.switchLight()
        case gamepad.buttonB:
            guard gamepad.buttonB.value != 0 else { break }
            delegate?.switchAuxPower()
        case gamepad.buttonY:
            guard gamepad.buttonY.value != 0 else { break }
            delegate?.switchRecording()
        case gamepad.buttonX:
            guard gamepad.buttonX.value != 0 else { break }
            delegate?.switchAuxRecording()
        default:
            break
        }
    }
}

extension TridentControl: TouchJoystickViewDelegate {
    func joystickDidMove(_ joystickView: TouchJoystickView, to x: Float, y: Float) {}
    func joystickEndMoving(_ joystickView: TouchJoystickView) {}

}
