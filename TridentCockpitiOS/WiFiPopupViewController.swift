/////
////  WiFiPopupViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import Moya
import PromiseKit

protocol WiFiPopupProtocol: NSObject {
    func enteredPassword(ssid: String, password: String)
}

class WiFiPopupViewController: UITableViewController, StoryboardInstantiable {

    weak var delegate: WiFiPopupProtocol?
    var ssids: [SSIDInfo] = []

    private let reuseIdentifier = "WiFiCell"
    private var tableWidth: CGFloat = 100
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
//            self.preferredContentSize = CGSize(width: self.tableWidth + 10, height: self.tableView.fittingSize.height + 4)
       }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    func alertGetPassword(ssid: String) {
//        let alert = NSAlert()
//        alert.messageText = NSLocalizedString("Please enter password for Wi-Fi network ", comment: "") + "\"" + ssid + "\""
//        alert.alertStyle = .informational
//        let passwordLabel = NSTextField(labelWithString: NSLocalizedString("Password:", comment: ""))
//        let passwordField = NSSecureTextField()
//        let stack = NSStackView(views: [passwordLabel, passwordField])
//        let width = 300 - passwordLabel.intrinsicContentSize.width - stack.spacing
//        passwordField.widthAnchor.constraint(equalToConstant: width).isActive = true
//        if let password = KeychainService.get(key: ssid) {
//            passwordField.stringValue = password
//        }
//        stack.frame = NSRect(x: 0, y: 0, width: 300, height: 20)
//        stack.orientation = .horizontal
//        stack.distribution = .fillProportionally
//        alert.accessoryView = stack
//        alert.addButton(withTitle: "Join")
//        alert.addButton(withTitle: "Cancel")
//
//        let responce = alert.runModal()
//        guard responce == .alertFirstButtonReturn else { return }
//        let password = passwordField.stringValue
//        self.delegate?.enteredPassword(ssid: ssid, password: password)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        timer?.invalidate()
        timer = nil
        dismiss(animated: true) {
            self.alertGetPassword(ssid: self.ssids[indexPath.row].ssid)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ssids.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == ssids.count - 1 {
            setViewSizeOnContent()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        let level: Int
        switch ssids[indexPath.row].signal {
        case 70...: level = 4;
        case 60..<70: level = 3;
        case 50..<60: level = 2;
        case 40..<50: level = 1;
        default: level = 0;
        }
        cell.imageView?.image = UIImage(named: "wifi-\(level)")
        cell.textLabel?.text = ssids[indexPath.row].ssid
//        let size = cell.sizeThatFits(<#T##size: CGSize##CGSize#>)
//        tableWidth = max(tableWidth, size.width)

        return cell
    }
}

