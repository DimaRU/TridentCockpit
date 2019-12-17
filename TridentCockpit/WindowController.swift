/////
////  WindowController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet var ssidLabel: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = "TridentVideoWindow"
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
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
            toolbarItem.image = NSImage(named: "wifi")!
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
        case .goDive:
            addedItem.target = self
            addedItem.action = #selector(goDiveScreen(_:))
        case .goMaintenance:
            addedItem.target = self
            addedItem.action = #selector(goMaintenanceScreen(_:))
        case .goPastDives:
            addedItem.target = self
            addedItem.action = #selector(goPastDivesScreen(_:))
        default: break
        }
    }
    
    @IBAction func goDiveScreen(_ sender: Any?) {
        toolbar.isVisible = false
        self.contentViewController?.children.first?.performSegue(withIdentifier: "DiveSeque", sender: sender)
    }
    
    @IBAction func goMaintenanceScreen(_ sender: Any?) {
        self.contentViewController?.children.first?.performSegue(withIdentifier: "MaintenanceSeque", sender: sender)
        toolbar.isVisible = false
    }

    @IBAction func goPastDivesScreen(_ sender: Any?) {
        self.contentViewController?.children.first?.performSegue(withIdentifier: "PastDivesSegue", sender: sender)
        toolbar.isVisible = false
    }

    /// - Tag: DefaultIdentifiers
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .goDive,
            .goMaintenance,
            .space,
            .connectWiFi,
            .wifiSSID
        ]
    }

    /// - Tag: AllowedToolbarItems
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ NSToolbarItem.Identifier.space,
                 NSToolbarItem.Identifier.flexibleSpace,
        ]
    }

}
