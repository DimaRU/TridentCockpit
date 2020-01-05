/////
////  ToolbarItemIdentifier.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

// Tag: - ItemIdentifiers
public extension NSToolbarItem.Identifier {
    static let goDive: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "GoDive")
    static let goMaintenance: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "GoMaintenance")
    static let goPastDives: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "GoPastDives")
    static let connectWiFi: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ConnectWiFi")
    static let wifiSSID: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "WifiSSID")
    static let connectCamera: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ConnectCamera")
    static let goDashboard: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "GoDashboard")
    static let ssidView: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "SSIDView")
    static let auxCameraModelView: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "AuxCameraModelView")
}

extension NSToolbar {
    func getItem(for identifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        return self.items.first(where: { $0.itemIdentifier == identifier})
    }
    func getButton(for identifier: NSToolbarItem.Identifier) -> NSButton? {
        return self.items.first(where: { $0.itemIdentifier == identifier})?.view as? NSButton
    }
}
