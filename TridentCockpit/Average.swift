/////
////  Average.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

@propertyWrapper
struct Average<T: BinaryFloatingPoint> {
    let max: Int
    private var count: Int
    private var average: T
    private var completion: ((T) -> Void)?

    init(_ max: Int) {
        self.max = max
        self.count = 0
        self.average = 0

    }

    mutating func configure(completion: @escaping ((T) -> Void)) {
        self.completion = completion
    }

    var wrappedValue: T {
        get {
            if count == 0 {
                return 0
            } else {
                return average / T(count)
            }
        }
        set {
            if count >= max {
                average = 0
                count = 0
            }
            average += newValue
            count += 1
            if count >= max {
                completion?(average / T(count))
            }
        }
    }
}
