/////
////  DisplayManage.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import IOKit.pwr_mgt

enum DisplayManager {
    private static var assertionID: IOPMAssertionID = 0
    private static var sleepDisabled = false
    
    static func disableSleep(reason: String = "Trident disable Screen Sleep") {
        guard !sleepDisabled else { return }
        sleepDisabled = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                    IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                    reason as CFString,
                                                    &assertionID) == kIOReturnSuccess
    }
    static func enableSleep() {
        guard sleepDisabled else { return }
        IOPMAssertionRelease(assertionID)
        sleepDisabled = false
    }
}

