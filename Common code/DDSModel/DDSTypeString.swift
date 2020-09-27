/////
////  DDSTypeString.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

extension String: DDSUnkeyed {
    public static var ddsTypeName: String { "DDS::String" }
}
