/////
////  CLLocation+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import CoreLocation

extension CLLocation  {
    var iso6709String: String {
        String(format: "%+09.5f%+010.5f%+.0fCRSWGS_84", self.coordinate.latitude, self.coordinate.longitude, self.altitude)
    }
}
