/////
////  ToolbarDelegate.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

extension DashboardViewController: NSToolbarDelegate {
    /// - Tag: ToolbarItemForIdentifier
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        toolbarItem.autovalidates = false

        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 44, height: 40))
        button.title = ""
        button.bezelStyle = .texturedRounded
        button.focusRingType = .none
        
        let size = NSSize(width: 50, height: 27)
        switch itemIdentifier {
        case .goDive:
            toolbarItem.label = NSLocalizedString("Pilot", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Pilot", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Pilot Trident", comment: "")
            button.image = NSImage(named: "underwater")!
            toolbarItem.view = button
            toolbarItem.minSize = size
            toolbarItem.maxSize = size
        case .goMaintenance:
            toolbarItem.label = NSLocalizedString("Maintenance", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Maintenance", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Maintenance Trident", comment: "")
            button.image = NSImage(named: NSImage.actionTemplateName)!
            toolbarItem.view = button
            toolbarItem.minSize = size
            toolbarItem.maxSize = size
        case .goPastDives:
            toolbarItem.label = NSLocalizedString("Past Dives", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Past Dives", comment: "")
            toolbarItem.toolTip = NSLocalizedString("View Past Dives video", comment: "")
            button.image = NSImage(named: NSImage.quickLookTemplateName)!
            toolbarItem.view = button
            toolbarItem.minSize = size
            toolbarItem.maxSize = size
        case .connectWiFi:
            toolbarItem.label = NSLocalizedString("WiFi", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("WiFi", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Connect Trident WiFi", comment: "")
            button.image = NSImage(named: "wifi.slash")!
            button.image = NSImage(named: "wifi")!
            toolbarItem.view = button
            toolbarItem.minSize = size
            toolbarItem.maxSize = size
        case .connectCamera:
            toolbarItem.label = NSLocalizedString("Payload", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Payload", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Connect camera payload", comment: "")
            button.image = NSImage(named: "camera.fill")!
            toolbarItem.view = button
            toolbarItem.minSize = size
            toolbarItem.maxSize = size
        default:
            break
        }
        return toolbarItem
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        let userInfo = notification.userInfo!
        guard let item = userInfo["item"] as? NSToolbarItem else { return }
        switch item.itemIdentifier {
        case .goDive:
            item.target = self
            item.action = #selector(goDiveScreen(_:))
        case .goMaintenance:
            item.target = self
            item.action = #selector(goMaintenanceScreen(_:))
        case .goPastDives:
            item.target = self
            item.action = #selector(goPastDivesScreen(_:))
        case .connectWiFi:
            item.target = self
            item.action = #selector(connectWifiButtonPress(_:))
        case .connectCamera:
            item.target = self
            item.action = #selector(connectCameraButtonPress(_:))
        default: break
        }
    }

    /// - Tag: DefaultIdentifiers
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .goDive,
            .goMaintenance,
            .space,
            .connectWiFi,
            .connectCamera,
        ]

    }

    /// - Tag: AllowedToolbarItems
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .goDive,
            .goMaintenance,
            .connectWiFi,
            .connectCamera,
            .space,
            .flexibleSpace,
            .separator,
        ]
    }

}

