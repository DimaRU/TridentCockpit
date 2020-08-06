/////
////  EqualizerView.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

class EqualizerView: UIView {
    @IBOutlet var eSliders: [EqSlider]!

    private var equalizerState: [String: RovCameraControl] = [:]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        layer.cornerRadius = 5
        layer.masksToBounds = true
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 150: 340
        heightAnchor.constraint(equalToConstant: height).isActive = true
        
        for slider in eSliders {
            guard let descriptor = ControlDescriptors.first(where: { $0.idString == slider.accessibilityLabel }) else { continue }
            
            slider.minimumValue = Float(descriptor.minimum)
            slider.maximumValue = Float(descriptor.maximum)
            slider.value = Float(descriptor.defaultValueNumeric)
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
        
        let control = RovCameraControl(id: descriptor.id,
                                       idString: idString,
                                       requestId: 0,
                                       errorCode: 0,
                                       setToDefault: false,
                                       value: controlValue)
        
        print(control)
     }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let idString = sender.accessibilityLabel else { return }
        let value = sender.value
        sendState(value: value, idString: idString)
        
        print(#function, idString, value)
    }
    
    @IBAction func resetButtonTap(_ sender: UIButton) {
        guard
            let idString = sender.accessibilityLabel,
            let descriptor = ControlDescriptors.first(where: { $0.idString == idString } ),
            let slider = eSliders.first(where: { $0.accessibilityLabel == idString})
        else { return }
        
        let value = Float(descriptor.defaultValueNumeric)
        print(#function, idString, value)
        sendState(value: value, idString: idString)
        slider.value = value
    }
    
    
    
}

fileprivate let ControlDescriptors = [
    RovControlDescriptor(id: 134217729, idString: "brightness", type: 1, name: "Brightness", unit: "n/a", minimum: -255, maximum: 255, step: 1, defaultValueNumeric: 0, defaultValueString: "", flags: 32, menuOptions: []),
    RovControlDescriptor(id: 134217730, idString: "contrast",   type: 5, name: "Contrast", unit: "n/a",   minimum: 0, maximum: 200, step: 1, defaultValueNumeric: 100, defaultValueString: "", flags: 32, menuOptions: []),
    RovControlDescriptor(id: 134217731, idString: "saturation", type: 5, name: "Saturation", unit: "n/a", minimum: 0, maximum: 200, step: 1, defaultValueNumeric: 100, defaultValueString: "", flags: 32, menuOptions: []),
    RovControlDescriptor(id: 134217732, idString: "hue",        type: 1, name: "Hue", unit: "n/a",        minimum: -18000, maximum: 18000, step: 1, defaultValueNumeric: 0, defaultValueString: "", flags: 32, menuOptions: []),
    RovControlDescriptor(id: 134217733, idString: "gamma",      type: 5, name: "Gamma", unit: "n/a",      minimum: 0, maximum: 300, step: 1, defaultValueNumeric: 0, defaultValueString: "", flags: 32, menuOptions: []),
    RovControlDescriptor(id: 134217735, idString: "sharpness",  type: 5, name: "Sharpness", unit: "n/a",  minimum: 1, maximum: 100, step: 1, defaultValueNumeric: 1, defaultValueString: "", flags: 32, menuOptions: []),
    RovControlDescriptor(id: 134217736, idString: "gain",       type: 5, name: "Gain", unit: "n/a",       minimum: 1, maximum: 100, step: 1, defaultValueNumeric: 1, defaultValueString: "", flags: 32, menuOptions: []),
    RovControlDescriptor(id: 134218028, idString: "bitrate",    type: 6, name: "Bitrate", unit: "bits/s", minimum: 1000, maximum: 10000000, step: 1, defaultValueNumeric: 1500000, defaultValueString: "", flags: 32, menuOptions: []),
]
  
