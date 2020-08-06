/////
////  EqualizerView.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

extension RovCameraControl.ControlUnion {
    var floatValue: Float? {
        switch self {
        case .S8(value: let value): return Float(value)
        case .S16(value: let value): return Float(value)
        case .S32(value: let value): return Float(value)
        case .S64(value: let value): return Float(value)
        case .U8(value: let value): return Float(value)
        case .U16(value: let value): return Float(value)
        case .U32(value: let value): return Float(value)
        case .U64(value: let value): return Float(value)
        default: return nil
        }
    }
}

class EqualizerView: UIView {
    @IBOutlet var eSliders: [EqSlider]!
    private var ControlDescriptors: [RovControlDescriptor] = []
    private var equalizerState: [String: RovCameraControl] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        layer.cornerRadius = 5
        layer.masksToBounds = true
        eSliders.forEach{ $0.superview?.isHidden = true }
        
        FastRTPS.registerWriter(topic: .rovCamFwdH2640CtrlRequested, ddsType: RovCameraControl.self)
        FastRTPS.registerWriter(topic: .rovCamFwdH2641CtrlRequested, ddsType: RovCameraControl.self)

        FastRTPS.registerReader(topic: .rovCamFwdH2640CtrlDesc) { [weak self] (descriptor: RovControlDescriptor) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let slider = self.eSliders.first(where: { $0.accessibilityLabel == descriptor.idString }) else { return }
                slider.minimumValue = Float(descriptor.minimum)
                slider.maximumValue = Float(descriptor.maximum)
                slider.value = Float(descriptor.defaultValueNumeric)
                if descriptor.idString == "hue" {
                    slider.minimumValue = 0
                    slider.maximumValue = Float(descriptor.maximum / 10)
                }
                slider.superview?.isHidden = false
                self.ControlDescriptors.append(descriptor)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentValueReader()
        }
    }

    private func currentValueReader() {
        FastRTPS.registerReader(topic: .rovCamFwdH2640CtrlCurrent) { [weak self] (cameraControl: RovCameraControl) in
            DispatchQueue.main.async {
                self?.equalizerState[cameraControl.idString] = cameraControl
                guard let slider = self?.eSliders.first(where: { $0.accessibilityLabel == cameraControl.idString }) else {
                    return
                }
                if let value = cameraControl.value.floatValue,
                    slider.value != value {
                    slider.value = value
                }
            }
        }
    }
    
    private func sendState(value: Float, idString: String) {
        guard let descriptor = ControlDescriptors.first(where: { $0.idString == idString } ) else { return }
        let controlValue: RovCameraControl.ControlUnion
        switch RovCameraControl.ControlUnion.init(rawValue: descriptor.type)! {
        case .S8: controlValue = .S8(value: Int8(value))
        case .S16: controlValue = .S16(value: Int16(value))
        case .S32: controlValue = .S32(value: Int32(value))
        case .S64: controlValue = .S64(value: Int64(value))
        case .U8: controlValue = .U8(value: UInt8(value))
        case .U16: controlValue = .U16(value: UInt16(value))
        case .U32: controlValue = .U32(value: UInt32(value))
        case .U64: controlValue = .U64(value: UInt64(value))
        case .Bitmask: controlValue = .Bitmask(bitmask: UInt32(value))
        case .IntMenu: controlValue = .IntMenu(intMenu: UInt32(value))
        case .StringMenu: controlValue = .StringMenu(stringMenu: UInt32(value))
        default:
            fatalError(#function)
        }
        
        let cameraControl = RovCameraControl(id: descriptor.id,
                                       idString: idString,
                                       requestId: 0,
                                       errorCode: 0,
                                       setToDefault: false,
                                       value: controlValue)
        
        
        FastRTPS.send(topic: .rovCamFwdH2640CtrlRequested, ddsData: cameraControl)
        FastRTPS.send(topic: .rovCamFwdH2641CtrlRequested, ddsData: cameraControl)
     }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let idString = sender.accessibilityLabel else { return }
        let value = sender.value
        sendState(value: value, idString: idString)
    }
    
    @IBAction func resetButtonTap(_ sender: UIButton) {
        guard
            let idString = sender.accessibilityLabel,
            let descriptor = ControlDescriptors.first(where: { $0.idString == idString } ),
            let slider = eSliders.first(where: { $0.accessibilityLabel == idString})
        else { return }
        
        let value = Float(descriptor.defaultValueNumeric)
        sendState(value: value, idString: idString)
        slider.value = value
    }
    
}
