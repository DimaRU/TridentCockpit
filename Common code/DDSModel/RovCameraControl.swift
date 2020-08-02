/////
////  RovCameraControl.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import FastRTPSBridge

struct RovCameraControl: DDSKeyed {
    
    enum ControlUnion: RawRepresentable, Codable {
        init?(rawValue: UInt32) {
            return nil
        }
        typealias RawValue = UInt32
        
        var rawValue: UInt32 {
            switch self {
            case .S8: return 0
            case .S16: return 1
            case .S32: return 2
            case .S64: return 3
            case .U8: return 4
            case .U16: return 5
            case .U32: return 6
            case .U64: return 7
            case .Bitmask: return 8
            case .Button: return 9
            case .Boolean: return 10
            case .StringValue: return 11
            case .StringMenu: return 12
            case .IntMenu: return 13
            }
        }
        
        case S8(value: Int8)
        case S16(value: Int16)
        case S32(value: Int32)
        case S64(value: Int64)
        case U8(value: UInt8)
        case U16(value: UInt16)
        case U32(value: UInt32)
        case U64(value: UInt64)
        case Bitmask(bitmask: UInt32)
        case Button(button: Bool)
        case Boolean(value: Bool)
        case StringValue(value: String)
        case StringMenu(stringMenu: UInt32)
        case IntMenu(intMenu: UInt32)
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let selector = try container.decode(UInt32.self)
            switch selector {
                case 0:
                    let value = try container.decode(Int8.self)
                    self = .S8(value: value)
                case 1:
                    let value = try container.decode(Int16.self)
                    self = .S16(value: value)
                case 2:
                    let value = try container.decode(Int32.self)
                    self = .S32(value: value)
                case 3:
                    let value = try container.decode(Int64.self)
                    self = .S64(value: value)
                case 4:
                    let value = try container.decode(UInt8.self)
                    self = .U8(value: value)
                case 5:
                    let value = try container.decode(UInt16.self)
                    self = .U16(value: value)
                case 6:
                    let value = try container.decode(UInt32.self)
                    self = .U32(value: value)
                case 7:
                    let value = try container.decode(UInt64.self)
                    self = .U64(value: value)
                case 8:
                    let value = try container.decode(UInt32.self)
                    self = .Bitmask(bitmask: value)
                case 9:
                    let value = try container.decode(Bool.self)
                    self = .Button(button: value)
                case 10:
                    let value = try container.decode(Bool.self)
                    self = .Boolean(value: value)
                case 11:
                    let value = try container.decode(String.self)
                    self = .StringValue(value: value)
                case 12:
                    let value = try container.decode(UInt32.self)
                    self = .StringMenu(stringMenu: value)
                case 13:
                    let value = try container.decode(UInt32.self)
                    self = .IntMenu(intMenu: value)
                default:
                    let error = DecodingError.dataCorruptedError(in: container, debugDescription: "Illegal union selector \(selector)")
                    throw error
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(self.rawValue)
            switch self {
            case .S8(value: let value): try container.encode(value)
            case .S16(value: let value): try container.encode(value)
            case .S32(value: let value): try container.encode(value)
            case .S64(value: let value): try container.encode(value)
            case .U8(value: let value): try container.encode(value)
            case .U16(value: let value): try container.encode(value)
            case .U32(value: let value): try container.encode(value)
            case .U64(value: let value): try container.encode(value)
            case .Bitmask(bitmask: let bitmask): try container.encode(bitmask)
            case .Button(button: let button): try container.encode(button)
            case .Boolean(value: let value): try container.encode(value)
            case .StringValue(value: let value): try container.encode(value)
            case .StringMenu(stringMenu: let stringMenu): try container.encode(stringMenu)
            case .IntMenu(intMenu: let intMenu): try container.encode(intMenu)
            }
        }
    }

    let id: UInt32           //@key
    let idString: String
    let requestId: UInt32
    let errorCode: Int16
    let setToDefault: Bool
    let value: ControlUnion

    
    var key: Data { String(id).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::image::ControlValue" }
}
