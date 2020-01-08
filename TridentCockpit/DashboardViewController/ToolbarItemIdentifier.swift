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
    static let connectCamera: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ConnectCamera")
//    static let goDashboard: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "GoDashboard")
}

extension NSToolbar {
    func getItem(for identifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        return self.items.first(where: { $0.itemIdentifier == identifier})
    }
    func getButton(for identifier: NSToolbarItem.Identifier) -> NSButton? {
        return self.items.first(where: { $0.itemIdentifier == identifier})?.view as? NSButton
    }
    
    func insertItem(withItemIdentifier itemIdentifier: NSToolbarItem.Identifier, after: NSToolbarItem.Identifier) {
        let index = self.items.firstIndex { $0.itemIdentifier == after }
        if let index = index {
            insertItem(withItemIdentifier: itemIdentifier, at: index + 1)
        }
    }
    func insertItem(withItemIdentifier itemIdentifier: NSToolbarItem.Identifier) {
        let item = items.firstIndex { $0.itemIdentifier == itemIdentifier }
        guard item == nil else { return }
        guard let index = delegate?.toolbarDefaultItemIdentifiers?(self).firstIndex(where: { $0 == itemIdentifier }) else { return }
        insertItem(withItemIdentifier: itemIdentifier, at: index)
    }
    func appendItem(withItemIdentifier itemIdentifier: NSToolbarItem.Identifier) {
        let item = items.firstIndex { $0.itemIdentifier == itemIdentifier }
        guard item == nil else { return }
        insertItem(withItemIdentifier: itemIdentifier, at: items.count)
    }
    func removeItem(itemIdentifier: NSToolbarItem.Identifier) {
        let index = self.items.firstIndex { $0.itemIdentifier == itemIdentifier }
        if let index = index {
            removeItem(at: index)
        }
    }
}
