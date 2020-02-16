/////
////  Date+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation

extension Date {
    var clearedTime: Date {
        get {
            let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
            return Calendar.current.date(from: dateComponents)!
        }
    }
}
