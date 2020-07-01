/////
////  WiFiPopupViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import Moya
import PromiseKit

protocol WiFiPopupProtocol: NSObject {
    func enteredPassword(ssid: String, password: String)
}

class WiFiPopupViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!

    weak var delegate: WiFiPopupProtocol?
    var ssids: [SSIDInfo] = []
    
    private var tableWidth: CGFloat = 0
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableWidth = tableView.tableColumns[0].minWidth
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            RestProvider.request(MultiTarget(WiFiServiceAPI.scan))
            .then {
                RestProvider.request(MultiTarget(WiFiServiceAPI.ssids))
            }.done { (ssids: [SSIDInfo]) in
                self.ssids = ssids.filter{!$0.ssid.contains("Trident-")}
                self.tableView.reloadData()
            }.catch {
                self.alert(error: $0)
            }
        }
    }
    
    func setViewSizeOnContent() {
        DispatchQueue.main.async {
            self.preferredContentSize = NSSize(width: self.tableWidth + 10, height: self.tableView.fittingSize.height + 4)
       }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        timer?.invalidate()
        timer = nil
    }
    
    func alertGetPassword(ssid: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Please enter password for Wi-Fi network ", comment: "") + "\"" + ssid + "\""
        alert.alertStyle = .informational
        let passwordLabel = NSTextField(labelWithString: NSLocalizedString("Password:", comment: ""))
        let passwordField = NSSecureTextField()
        let stack = NSStackView(views: [passwordLabel, passwordField])
        let width = 300 - passwordLabel.intrinsicContentSize.width - stack.spacing
        passwordField.widthAnchor.constraint(equalToConstant: width).isActive = true
        if let password = KeychainService.get(key: ssid) {
            passwordField.stringValue = password
        }
        stack.frame = NSRect(x: 0, y: 0, width: 300, height: 20)
        stack.orientation = .horizontal
        stack.distribution = .fillProportionally
        alert.accessoryView = stack
        alert.addButton(withTitle: "Join")
        alert.addButton(withTitle: "Cancel")

        let responce = alert.runModal()
        guard responce == .alertFirstButtonReturn else { return }
        let password = passwordField.stringValue
        self.delegate?.enteredPassword(ssid: ssid, password: password)
    }
}

extension WiFiPopupViewController: NSTableViewDelegate {
    func tableViewSelectionIsChanging(_ notification: Notification) {
        guard tableView.selectedRow != -1 else { return }
        timer?.invalidate()
        timer = nil
        dismiss(nil)
        DispatchQueue.main.async {
            self.alertGetPassword(ssid: self.ssids[self.tableView.selectedRow].ssid)
        }
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
