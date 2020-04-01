/////
////  NSViewController+Alert.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

extension NSViewController {
    func alert(message: String, informative: String, delay: Int = 5) {
        self.view.window?.alert(message: message, informative: informative, delay: delay)
    }
    
    func alert(error: Error, delay: Int = 4) {
        self.view.window?.alert(error: error, delay: delay)
    }
}
