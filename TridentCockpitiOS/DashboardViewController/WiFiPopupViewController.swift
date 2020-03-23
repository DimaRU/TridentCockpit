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

    private var contentSizeObserver: NSKeyValueObservation?
    private let reuseIdentifier = "WiFiCell"
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        self.preferredContentSize = CGSize(width: 300, height: 50)
        tableView.separatorStyle = .none

        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            RestProvider.request(MultiTarget(WiFiServiceAPI.scan))
            .then {
                RestProvider.request(MultiTarget(WiFiServiceAPI.ssids))
            }.done { (ssids: [SSIDInfo]) in
                self.ssids = ssids.filter{!$0.ssid.contains("Trident-")}
                self.tableView.reloadData()
            }.catch {
                $0.alert()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        contentSizeObserver = tableView.observe(\.contentSize) { [weak self] tableView, _ in
            self?.preferredContentSize = tableView.contentSize
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
        contentSizeObserver?.invalidate()
        contentSizeObserver = nil
    }
    
    func alertGetPassword(ssid: String) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.title = NSLocalizedString("Please enter password for Wi-Fi network ", comment: "") + "\"" + ssid + "\""
        alert.addTextField { passwordField in
            passwordField.isSecureTextEntry = true
            if let password = KeychainService.get(key: ssid) {
                passwordField.text = password
            }
        }
        let joinAction = UIAlertAction(title: "Join", style: .default) { _ in
            guard let password = alert.textFields?.first?.text else { return }
            self.delegate?.enteredPassword(ssid: ssid, password: password)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(joinAction)
        alert.addAction(cancelAction)
        var presenter = presentingViewController
        if let navController = presenter as? UINavigationController {
            presenter = navController.viewControllers.first
        }
        if let popoverController = alert.popoverPresentationController, let view = presenter?.view {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        dismiss(animated: true) {
            presenter?.present(alert, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        timer?.invalidate()
        timer = nil
        self.alertGetPassword(ssid: self.ssids[indexPath.row].ssid)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ssids.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        let level: Int
        switch ssids[indexPath.row].signal {
        case 70...: level = 4;
        case 60..<70: level = 3;
        case 50..<60: level = 2;
        case 40..<50: level = 1;
        default: level = 0;
        }
        cell.imageView?.image = UIImage(named: "wifi-\(level)")!
        cell.textLabel?.text = ssids[indexPath.row].ssid

        return cell
    }
}
