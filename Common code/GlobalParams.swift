/////
////  GlobalParams.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

@propertyWrapper
struct Param<T> {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var wrappedValue: T {
        GlobalParams.plist[key] as! T
    }
}

fileprivate func getPlist(withName name: String) -> [String: Any]
{
    guard let path = Bundle.main.path(forResource: name, ofType: "plist"),
        let xml = FileManager.default.contents(atPath: path) else {
            fatalError("Error loading \(name).plist")
    }
    return (try! PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil)) as! [String: Any]
}

class GlobalParams {
    static let plist = getPlist(withName: "GlobalParams")

    @Param("BasePort")
    static var basePort: Int
    
    @Param("RovLogin")
    static var rovLogin: String
    
    @Param("RovPassword")
    static var rovPassword: String
    
    @Param("ImageVersion")
    static var targetImageVersion: String
}
