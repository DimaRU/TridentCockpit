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
                self.view.window?.alert(error: $0)
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
}

extension WiFiPopupViewController: NSTableViewDelegate {
    func tableViewSelectionIsChanging(_ notification: Notification) {
        guard tableView.selectedRow != -1 else { return }
        timer?.invalidate()
        timer = nil
        let controller: GetSSIDPasswordViewController = NSViewController.instantiate()
        controller.delegate = delegate
        controller.ssid = ssids[tableView.selectedRow].ssid
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

