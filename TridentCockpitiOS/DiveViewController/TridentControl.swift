/////
////  TridentControl.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


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
    var motorSpeed: MotorSpeed = .first

    func setup(delegate: TridentControlDelegate) {
        self.delegate = delegate
        connectGameController()
        ObserveForGameControllers()
    }
    
    func enable() {
        tridentCommandTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true, block: controlTimerBlock)
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
    
    @available(macCatalyst 13.4, iOS 13.4, *)
    func process(key: UIKey, began: Bool) -> Bool {
        var lever: Float = 0.1
        if key.modifierFlags.contains(.alternate) { lever = 0.25 }
        if key.modifierFlags.contains(.control) { lever = 0.50 }
        if key.modifierFlags.contains(.shift) { lever = 1 }
        if began {
            switch key.charactersIgnoringModifiers {
            case UIKeyCommand.inputUpArrow:
                forwardLever = lever
                backwardLever = 0
            case UIKeyCommand.inputDownArrow:
                backwardLever = lever
                forwardLever = 0
            case UIKeyCommand.inputLeftArrow:
                leftLever = lever
                rightLever = 0
            case UIKeyCommand.inputRightArrow:
                rightLever = lever
                leftLever = 0
            case "w":
                upLever = lever
                downLever = 0
            case "s":
                downLever = lever
                upLever = 0
            case "1":
                motorSpeed = .first
                self.delegate?.updatePropellerButtonState()
            case "2":
                motorSpeed = .second
                self.delegate?.updatePropellerButtonState()
            case "3":
                motorSpeed = .third
                self.delegate?.updatePropellerButtonState()
            default:
                return false
            }
        } else {
            switch key.charactersIgnoringModifiers {
            case UIKeyCommand.inputUpArrow:
                forwardLever = 0
            case UIKeyCommand.inputDownArrow:
                backwardLever = 0
            case UIKeyCommand.inputLeftArrow:
                leftLever = 0
            case UIKeyCommand.inputRightArrow:
                rightLever = 0
            case "w":
                upLever = 0
            case "s":
                downLever = 0
            default:
                return false
            }
        }
        return true
    }
    
    func ObserveForGameControllers() {
        connectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { _ in
            self.connectGameController()
        }
        
        disconnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { _ in
        }
    }
    
    private func connectGameController() {
        var indexNumber = 0
        for controller in GCController.controllers() {
            if controller.extendedGamepad != nil {
                if #available(iOS 13.0, *) {
                    print(controller.productCategory)
                }
                controller.playerIndex = GCControllerPlayerIndex(rawValue: indexNumber)!
                indexNumber += 1
                controller.extendedGamepad!.valueChangedHandler = { [weak self] (gamepad: GCExtendedGamepad, element: GCControllerElement) in
                    self?.controllerInputDetected(gamepad: gamepad, element: element, index: controller.playerIndex.rawValue)
                }
            }
        }
    }
    
    private func controllerInputDetected(gamepad: GCExtendedGamepad, element: GCControllerElement, index: Int) {
        switch element {
        case gamepad.leftThumbstick:
            forwardLever = gamepad.leftThumbstick.yAxis.value * motorSpeed.rate
            backwardLever = 0
        case gamepad.rightThumbstick:
            rightLever = gamepad.rightThumbstick.xAxis.value * motorSpeed.rate
            leftLever = 0
            downLever = gamepad.rightThumbstick.yAxis.value * motorSpeed.rate
            upLever = 0
        case gamepad.leftShoulder:
            guard gamepad.leftShoulder.value != 0 else { break }
            guard motorSpeed != .first else { break }
            motorSpeed = MotorSpeed(rawValue: motorSpeed.rawValue - 1) ?? MotorSpeed.first
            self.delegate?.updatePropellerButtonState()
        case gamepad.rightShoulder:
            guard gamepad.rightShoulder.value != 0 else { break }
            guard motorSpeed != .third else { break }
            motorSpeed = MotorSpeed(rawValue: motorSpeed.rawValue + 1) ?? MotorSpeed.third
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

#if os(iOS)
extension TridentControl: TouchJoystickViewDelegate {
    func joystickDidMove(_ joystickType: TouchJoystickView.JoystickType, to x: Float, y: Float) {
        switch joystickType {
        case .vertical:
            forwardLever = y * motorSpeed.rate
            backwardLever = 0
        case .dualAxis:
            rightLever = x * motorSpeed.rate
            downLever = y * motorSpeed.rate
            upLever = 0
            leftLever = 0
        case .horizontal:
            fatalError()
        }
    }
    
    func joystickEndMoving(_ joystickType: TouchJoystickView.JoystickType) {
        switch joystickType {
        case .vertical:
            forwardLever = 0
            backwardLever = 0
        case .dualAxis:
            rightLever = 0
            leftLever = 0
            upLever = 0
            downLever = 0
        case .horizontal:
            fatalError()
        }
    }
    
}
#endif
