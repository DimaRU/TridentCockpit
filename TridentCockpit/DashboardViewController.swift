/////
////  DashboardViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import FastRTPSBridge
import CircularProgress
import Moya
import PromiseKit
import SwiftSH

class DashboardViewController: NSViewController {
    let stdParticipantList: Set<String> = ["geoserve", "trident-core", "trident-control", "trident-update", "trident-record"]
    var tridentParticipants: Set<String> = []
    var tridentID: String!
    weak var toolbar: NSToolbar?
    var sshCommand: SSHCommand!
    var deviceState: DeviceState?

    var connectedSSID: String? {
        didSet {
            guard let wifiItem = toolbar?.getItem(for: .connectWiFi),
                let button = wifiItem.view as? NSButton,
                let textField = toolbar?.getItem(for: .wifiSSID)?.view as? NSTextField else { return }
            if connectedSSID != nil {
                textField.stringValue = connectedSSID!
                wifiItem.label = NSLocalizedString("Disconnect WiFi", comment: "")
                wifiItem.paletteLabel = NSLocalizedString("Disconnect WiFi", comment: "")
                wifiItem.toolTip = NSLocalizedString("Disconnect Trident WiFi", comment: "")
                button.image = NSImage(named: "wifi.slash")!
                toolbar?.getItem(for: .connectCamera)?.isEnabled = true
            } else {
                textField.stringValue = NSLocalizedString("Not connected", comment: "")
                wifiItem.label = NSLocalizedString("Connect WiFi", comment: "")
                wifiItem.paletteLabel = NSLocalizedString("Connect WiFi", comment: "")
                wifiItem.toolTip = NSLocalizedString("Connect Trident WiFi", comment: "")
                button.image = NSImage(named: "wifi")!
                toolbar?.getItem(for: .connectCamera)?.isEnabled = false
            }
        }
    }

    
    @IBOutlet weak var gridView: NSGridView!
    @IBOutlet weak var spinner: CircularProgress!
    @IBOutlet weak var tridentIdLabel: NSTextField!
    @IBOutlet weak var tridentNetworkAddressLabel: NSTextField!
    @IBOutlet weak var localAddressLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gridView.isHidden = true
        setupNotifications()
        getConnection()
    }
    
    override func viewDidAppear() {
        toolbar = view.window?.toolbar
        toolbar?.isVisible = true
        setupToolbarButtons()
    }
    
    override func viewWillDisappear() {
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destinationController = segue.destinationController as? DiveViewController {
            destinationController.vehicleId = tridentID
        }
    }
    
    @IBAction func goDiveScreen(_ sender: Any?) {
        toolbar?.isVisible = false
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "DiveSeque", sender: nil)
        }
    }
        
    @IBAction func goMaintenanceScreen(_ sender: Any?) {
        toolbar?.isVisible = false
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "MaintenanceSeque", sender: sender)
        }
        
    }
    
    @IBAction func goPastDivesScreen(_ sender: Any?) {
        toolbar?.isVisible = false
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "PastDivesSegue", sender: sender)
        }
    }

    @IBAction func connectWifiButtonPress(_ sender: NSButton) {
        if connectedSSID == nil {
            connectWiFi(view: sender.superview!)
        } else {
            disconnectWiFi()
        }
    }

    @IBAction func connectCameraButtonPress(_ sender: Any?) {
        executeScript(name: "PayloadProvision")
    }

    private func disconnectWiFi() {
        RestProvider.request(MultiTarget(WiFiServiceAPI.disconnect))
        .then { _ in
            RestProvider.request(MultiTarget(WiFiServiceAPI.clear))
        }.done {
            self.connectedSSID = nil
        }.catch { error in
            print(error)
        }
    }

    private func connectWiFi(view: NSView) {
        RestProvider.request(MultiTarget(WiFiServiceAPI.scan))
        .then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.ssids))
        }.done { (ssids: [SSIDInfo]) -> Void in
            self.showPopup(with: ssids, view: view)
        }.catch { error in
            print(error)
        }
    }

    private func showPopup(with ssids: [SSIDInfo], view: NSView) {
        let controller: WiFiPopupViewController = WiFiPopupViewController.instantiate()
        controller.delegate = self
        controller.ssids = ssids
        present(controller, asPopoverRelativeTo: .zero, of: view, preferredEdge: .minY, behavior: .transient)
   }

    private func executeScript(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "sh") else { return }
        guard let scriptBody = try? String(contentsOf: url) else { return }

        let exposeIP = Bundle.main.infoDictionary!["ExposeIP"]! as! String
        let login = Bundle.main.infoDictionary!["RovLogin"]! as! String
        let passwordBase64 = Bundle.main.infoDictionary!["RovPassword"]! as! String
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!

        var header = "#/bin/bash\n"
        header += "echo \(password) | sudo -S echo START-SCRIPT\n"
        header += "exec 2>&1\n"
        header += "SOURCEIP=\(FastRTPS.localAddress)\n"
        header += "EXPOSEIP=\(exposeIP)\n"
        print(header+scriptBody)
        sshCommand = try! SSHCommand(host: FastRTPS.remoteAddress)
        sshCommand.log.level = .error
        sshCommand.timeout = 10000

        sshCommand.connect()
            .authenticate(.byPassword(username: login, password: password))
            .execute(header+scriptBody) { [unowned self] (command, log: String?, error) in
                if let log = log {
                    let logStrings = log.split(separator: "\n")
                    if logStrings.last != "OK-SCRIPT" {
                        print(logStrings.filter { !$0.contains("sudo: unable to resolve host") && !$0.contains("START-SCRIPT") })
                    }
                } else {
                    print("ERROR: \(String(describing: error))")
                }
                self.sshCommand.disconnect {}
        }
    }

    private func getConnection() {
        var interfaceAddresses: Set<String> = []
        DispatchQueue.global(qos: .userInteractive).async {
            repeat {
                interfaceAddresses = FastRTPS.getIP4Address()
                if interfaceAddresses.isEmpty {
                    Thread.sleep(forTimeInterval: 0.5)
                }
            } while interfaceAddresses.isEmpty
            self.startRTPS(addresses: interfaceAddresses)
        }
    }
    
    private func startRTPS(addresses: Set<String>) {
        print(addresses)
        let address = addresses.first { $0.starts(with: "10.1.1.") } ?? addresses.first!
        FastRTPS.localAddress = address
        print("Local address:", address)
        let network = address + "/24"
        FastRTPS.createParticipant(interfaceIPv4: address, networkAddress: network)
    }
    
    func setConnectedState() {
        spinner.isHidden = true
        spinner.isIndeterminate = false
        gridView.isHidden = false
        
        view.window?.title = tridentID
        tridentIdLabel.stringValue = tridentID
        tridentNetworkAddressLabel.stringValue = FastRTPS.remoteAddress
        localAddressLabel.stringValue = FastRTPS.localAddress
        
        RestProvider.request(MultiTarget(ResinAPI.deviceState))
        .then { (deviceState: DeviceState) -> Promise<[ConnectionInfo]> in
            self.deviceState = deviceState
            self.tridentNetworkAddressLabel.stringValue = deviceState.ipAddress
            return RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
        }.done { connectionInfo in
            if let ssid = connectionInfo.first(where: {$0.kind == "802-11-wireless"})?.ssid {
                self.connectedSSID = ssid
            } else {
                self.connectedSSID = nil
            }
        }.catch { error in
            print(error)
        }
        if let toolbar = view.window?.toolbar {
            toolbar.getItem(for: .goDive)?.isEnabled = true
            toolbar.getItem(for: .goMaintenance)?.isEnabled = true
            toolbar.getItem(for: .goPastDives)?.isEnabled = true
            toolbar.getItem(for: .connectWiFi)?.isEnabled = true
        }
        FastRTPS.setPartition(name: tridentID)
    }
    
    private func setupToolbarButtons() {
        guard let toolbar = toolbar else { return }
        toolbar.items.forEach { item in
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
            default:
                break
            }
//            item.isEnabled = false
        }
    }

}

extension DashboardViewController: GetSSIDPasswordProtocol {
    func enteredPassword(ssid: String, password: String) {
        RestProvider.request(MultiTarget(WiFiServiceAPI.connect(ssid: ssid, passphrase: password)))
        .then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
        }.done { (connectionInfo: [ConnectionInfo]) in
            if let ssid = connectionInfo.first(where: {$0.kind == "802-11-wireless"})?.ssid {
                self.connectedSSID = ssid
                KeychainService.set(password, key: ssid)
            }
        }.then {
            RestProvider.request(MultiTarget(ResinAPI.deviceState))
        }.done { (deviceState: DeviceState) in
            self.deviceState = deviceState
            self.tridentNetworkAddressLabel.stringValue = deviceState.ipAddress
        }.catch { error in
            print(error)
        }
    }
}
