/////
////  WindowController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet var ssidLabel: NSTextField!
    @IBOutlet var wifiConnectButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = "TridentVideoWindow"
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
    }

    func windowWillClose(_ notification: Notification) {
        FastRTPS.resignAll()
        FastRTPS.stopRTPS()
        if #available(OSX 10.15, *) {} else {
            DisplayManager.enableSleep()
        }
    }
}

// MARK: - NSToolbarDelegate
extension WindowController: NSToolbarDelegate {
    /// - Tag: ToolbarItemForIdentifier
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        toolbarItem.autovalidates = false
        toolbarItem.isEnabled = false

        switch itemIdentifier {
        case .goDive:
            toolbarItem.label = NSLocalizedString("Pilot", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Pilot", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Pilot Trident", comment: "")
            toolbarItem.image = NSImage(named: "underwater")!
        case .goMaintenance:
            toolbarItem.label = NSLocalizedString("Maintenance", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Maintenance", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Maintenance Trident", comment: "")
            toolbarItem.image = NSImage(named: NSImage.actionTemplateName)!
        case .goPastDives:
            toolbarItem.label = NSLocalizedString("Past Dives", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Past Dives", comment: "")
            toolbarItem.toolTip = NSLocalizedString("View Past Dives video", comment: "")
            toolbarItem.image = NSImage(named: NSImage.quickLookTemplateName)!
        case .connectWiFi:
            toolbarItem.label = NSLocalizedString("WiFi connect", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("WiFi connect", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Connect Trident WiFi", comment: "")
            toolbarItem.view = wifiConnectButton
        case .connectCamera:
            toolbarItem.label = NSLocalizedString("Camera connect", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("Camera connect", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Connect camera payload", comment: "")
            toolbarItem.image = NSImage(named: "camera.fill")!
        case .wifiSSID:
            toolbarItem.label = NSLocalizedString("SSID", comment: "")
            toolbarItem.paletteLabel = NSLocalizedString("SSID", comment: "")
            toolbarItem.toolTip = NSLocalizedString("Connected SSID", comment: "")
            toolbarItem.view = ssidLabel
            toolbarItem.isEnabled = true
        default:
            break
        }
        return toolbarItem
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        let userInfo = notification.userInfo!
        guard let addedItem = userInfo["item"] as? NSToolbarItem else { return }
        switch addedItem.itemIdentifier {
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
            .wifiSSID,
            .space,
            .connectCamera
        ]
    }

    /// - Tag: AllowedToolbarItems
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ NSToolbarItem.Identifier.space,
                 NSToolbarItem.Identifier.flexibleSpace,
        ]
    }

}
