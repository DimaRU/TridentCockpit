/////
////  Bundle+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation

extension Bundle {
  var versionNumber: String? {
    infoDictionary?["CFBundleShortVersionString"] as? String
  }
    
  var buildNumber: String? {
    infoDictionary?["CFBundleVersion"] as? String
  }
}
