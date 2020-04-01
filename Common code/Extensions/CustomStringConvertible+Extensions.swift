/////
////  CustomStringConvertible+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

#if DEBUG
import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import Cocoa
#endif

extension CLDeviceOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        @unknown default: return "unknown"
        }
    }
}

#if os(iOS)
extension UIInterfaceOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        @unknown default: return "unknown"
        }
    }
}
#endif

#endif
