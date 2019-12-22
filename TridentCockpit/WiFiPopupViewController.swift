/////
////  WiFiPopupViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa
import Moya
import PromiseKit

class WiFiPopupViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!

    weak var delegate: GetSSIDPasswordProtocol?
    var ssids: [SSIDInfo] = []
    
    private var tableWidth: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableWidth = tableView.tableColumns[0].minWidth
        
    }
    
    func setViewSizeOnContent() {
        DispatchQueue.main.async {
            self.preferredContentSize = NSSize(width: self.tableWidth + 10, height: self.tableView.fittingSize.height + 4)
       }
    }

}

extension WiFiPopupViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow != -1 else { return }
        let controller: GetSSIDPasswordViewController = NSViewController.instantiate()
        controller.delegate = delegate
        controller.ssid = ssids[tableView.selectedRow].ssid
//        let cellView = tableView.view(atColumn: 0, row: tableView.selectedRow, makeIfNecessary: false)!
        presentAsModalWindow(controller)
        dismiss(nil)
    }
}

extension WiFiPopupViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return ssids.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == ssids.count - 1 {
            setViewSizeOnContent()
        }
        guard let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        let level: Int
        switch ssids[row].signal {
        case 70...: level = 4;
        case 60..<70: level = 3;
        case 50..<60: level = 2;
        case 40..<50: level = 1;
        default: level = 0;
        }
        cellView.imageView?.image = NSImage(named: "wifi-\(level)")
        cellView.textField?.stringValue = ssids[row].ssid
        let size = cellView.fittingSize
        tableWidth = max(tableWidth, size.width)

        return cellView
    }
}

