/////
////  RovQuaternion+extensions.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import SceneKit

extension RovQuaternion {
    func scnQuaternion() -> SCNQuaternion {
        return SCNQuaternion(-x, -z, -y, w)
    }
}

extension RovQuaternion {
    var pitch: Double {
        return asin(min(1, max(-1, 2 * (w * y - z * x))))
    }

    var yaw: Double {
        return atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
    }

    var roll: Double {
        return atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))
    }

    init(pitch: Double, yaw: Double, roll: Double) {
        let t0 = cos(yaw * 0.5)
        let t1 = sin(yaw * 0.5)
        let t2 = cos(roll * 0.5)
        let t3 = sin(roll * 0.5)
        let t4 = cos(pitch * 0.5)
        let t5 = sin(pitch * 0.5)
        self.init(
            x: t0 * t3 * t4 - t1 * t2 * t5,
            y: t0 * t2 * t5 + t1 * t3 * t4,
            z: t1 * t2 * t4 - t0 * t3 * t5,
            w: t0 * t2 * t4 + t1 * t3 * t5
        )
    }
}
