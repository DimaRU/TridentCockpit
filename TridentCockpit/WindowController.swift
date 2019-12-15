/////
////  WindowController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet weak var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = "TridentVideoWindow"
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
    }

}

// MARK: - NSToolbarDelegate
extension WindowController: NSToolbarDelegate {
    /**    NSToolbar delegates require this function.
     It takes an identifier, and returns the matching NSToolbarItem. It also takes a parameter telling
     whether this toolbar item is going into an actual toolbar, or whether it's going to be displayed
     in a customization palette.
     */
    /// - Tag: ToolbarItemForIdentifier
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        print(#function, itemIdentifier.rawValue)

        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

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
        default:
            break
        }
        return toolbarItem
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        let userInfo = notification.userInfo!
        guard let addedItem = userInfo["item"] as? NSToolbarItem else { return }
        print(#function, addedItem.itemIdentifier.rawValue)
        switch addedItem.itemIdentifier {
        case .goDive:
            addedItem.target = self
            addedItem.action = #selector(goDiveScreen(_:))
        case .goPastDives:
            addedItem.target = self
            addedItem.action = #selector(goPastDivesScreen(_:))
        default: break
        }
    }
    
    @IBAction func goDiveScreen(_ sender: Any?) {
        self.contentViewController?.children.first?.performSegue(withIdentifier: "DiveSeque", sender: sender)
        toolbar.isVisible = false
    }
    
    
    @IBAction func goPastDivesScreen(_ sender: Any?) {
        self.contentViewController?.children.first?.performSegue(withIdentifier: "PastDivesSegue", sender: sender)
        toolbar.isVisible = false
    }

    /// - Tag: DefaultIdentifiers
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        print(#function)
        return [
            NSToolbarItem.Identifier.goDive,
            NSToolbarItem.Identifier.goMaintenance,
            NSToolbarItem.Identifier.goPastDives
        ]
    }

    /// - Tag: AllowedToolbarItems
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        print(#function)
        return [ NSToolbarItem.Identifier.space,
                 NSToolbarItem.Identifier.flexibleSpace,
        ]
    }

}
