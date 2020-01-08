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
    weak var toolbar: NSToolbar?

    let stdParticipantList: Set<String> = ["geoserve", "trident-core", "trident-control", "trident-update", "trident-record"]
    var tridentParticipants: Set<String> = []
    var tridentID: String!
    var discovered: [String: String] = [:]
    var ddsListener: DDSDiscoveryListener!
    private var sshCommand: SSHCommand!
    private var timer: Timer?
    private var spinner: CircularProgress?

    var deviceState: DeviceState? {
        didSet {
            guard oldValue != deviceState else { return }
            if deviceState != nil {
                let addrs = deviceState!.ipAddress.split(separator: " ")
                tridentNetworkAddressLabel.stringValue = String(addrs.first{ $0.contains("10.1.1.") } ?? "n/a")
                payloadAddress.stringValue = String(addrs.first{ !$0.contains("10.1.1.") } ?? "n/a")
            }
        }
    }
    var connectedSSID: String? {
        didSet {
            guard let toolbar = toolbar,
                let wifiItem = toolbar.getItem(for: .connectWiFi),
                let button = wifiItem.view as? NSButton else { return }
            if connectedSSID != nil {
                toolbar.appendItem(withItemIdentifier: .wifiSSID)
                toolbar.appendItem(withItemIdentifier: .connectCamera)

                DispatchQueue.main.async {
                    let textField = toolbar.getItem(for: .wifiSSID)?.view as? NSTextField
                    textField?.stringValue = self.connectedSSID!
                }
                wifiItem.label = NSLocalizedString("Disconnect", comment: "")
                wifiItem.paletteLabel = NSLocalizedString("Disconnect WiFi", comment: "")
                wifiItem.toolTip = NSLocalizedString("Disconnect Trident WiFi", comment: "")
                button.image = NSImage(named: "wifi.slash")!
            } else {
                toolbar.removeItem(itemIdentifier: .auxCameraModel)
                toolbar.removeItem(itemIdentifier: .connectCamera)
                toolbar.removeItem(itemIdentifier: .wifiSSID)
                
                wifiItem.label = NSLocalizedString("Connect", comment: "")
                wifiItem.paletteLabel = NSLocalizedString("Connect WiFi", comment: "")
                wifiItem.toolTip = NSLocalizedString("Connect Trident WiFi", comment: "")
                button.image = NSImage(named: "wifi")!
                Gopro3API.cameraPassword = nil
            }
        }
    }

    
    // MARK: Outlets
    @IBOutlet weak var gridView: NSGridView!
    @IBOutlet weak var tridentIdLabel: NSTextField!
    @IBOutlet weak var connectionAddress: NSTextField!
    @IBOutlet weak var tridentNetworkAddressLabel: NSTextField!
    @IBOutlet weak var localAddressLabel: NSTextField!
    @IBOutlet weak var payloadAddress: NSTextField!
    
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gridView.isHidden = true
        spinner = addCircularProgressView(to: view)
        setupNotifications()
        ddsDiscovery()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        if toolbar == nil {
            toolbar = view.window?.toolbar
            toolbar?.delegate = self
            setupToolbarButtons()
        }
        toolbar?.isVisible = true
        
        if FastRTPS.remoteAddress != "" {
            startRefreshDeviceState()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        toolbar?.isVisible = false
        
        timer?.invalidate()
        timer = nil
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destinationController = segue.destinationController as? DiveViewController {
            destinationController.vehicleId = tridentID
        }
    }
    
    // MARK: Actions
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
        guard deviceState?.ipAddress.split(separator: " ").count == 2 else { return }
        executeScript(name: "PayloadProvision") {
            self.connectGopro3()
        }
    }

    func addCircularProgressView(to view: NSView) -> CircularProgress {
        let spinner = CircularProgress(size: 200)
        spinner.lineWidth = 4
        spinner.isIndeterminate = true
        spinner.color = NSColor.systemTeal
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = NSTextField(labelWithString: "Searching for Trident")
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        spinner.addSubview(textLabel)
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.widthAnchor.constraint(equalToConstant: 200),
            spinner.heightAnchor.constraint(equalToConstant: 200),
            textLabel.centerXAnchor.constraint(equalTo: spinner.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: spinner.centerYAnchor),
            view.centerXAnchor.constraint(equalTo: spinner.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: spinner.centerYAnchor),
        ])
        return spinner
    }

    private func startRefreshDeviceState() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            RestProvider.request(MultiTarget(ResinAPI.deviceState))
            .done { (deviceState: DeviceState) in
                self.deviceState = deviceState
            }.catch { error in
                switch error {
                case NetworkError.unaviable(let message):
                    self.timer?.invalidate()
                    self.timer = nil
                    self.view.window?.alert(message: "Trident connection lost", informative: message, delay: 2)
                default:
                    self.view.window?.alert(error: error, delay: 2)
                }
            }
        }
    }
    
    // MARK: Private func
    private func disconnectWiFi() {
        RestProvider.request(MultiTarget(WiFiServiceAPI.disconnect))
        .then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.clear))
        }.done {
            self.connectedSSID = nil
            self.executeScript(name: "PayloadCleanup") {}
        }.catch {
            self.view.window?.alert(error: $0)
        }
    }

    private func connectWiFi(view: NSView) {
        RestProvider.request(MultiTarget(WiFiServiceAPI.scan))
        .then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.ssids))
        }.done { (ssids: [SSIDInfo]) -> Void in
            self.showPopup(with: ssids.filter{!$0.ssid.contains("Trident-")}, view: view)
        }.catch {
            self.view.window?.alert(error: $0)
        }
    }

    private func showPopup(with ssids: [SSIDInfo], view: NSView) {
        let controller: WiFiPopupViewController = WiFiPopupViewController.instantiate()
        controller.delegate = self
        controller.ssids = ssids
        present(controller, asPopoverRelativeTo: .zero, of: view, preferredEdge: .minY, behavior: .transient)
    }

    private func executeScript(name: String, completion: @escaping (() -> Void)) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "sh") else { return }
        guard let scriptBody = try? String(contentsOf: url) else { return }
        
        let basePort = Bundle.main.infoDictionary!["BasePort"]! as! String
        let redirectPorts = Bundle.main.infoDictionary!["RedirectPorts"]! as! String
        let login = Bundle.main.infoDictionary!["RovLogin"]! as! String
        let passwordBase64 = Bundle.main.infoDictionary!["RovPassword"]! as! String
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        
        var header = "#/bin/bash\n"
        header += "echo \(password) | sudo -S echo START-SCRIPT\n"
        header += "exec 2>&1\n"
        header += "SOURCEIP=\(FastRTPS.localAddress)\n"
        header += "BASEPORT=\(basePort)\n"
        header += "REDIRECTPORTS=(\(redirectPorts))\n"
        sshCommand = try! SSHCommand(host: FastRTPS.remoteAddress)
        sshCommand.log.level = .error
        sshCommand.timeout = 10000

        sshCommand.connect()
            .authenticate(.byPassword(username: login, password: password))
            .execute(header+scriptBody) { [weak self] (command, log: String?, error) in
                guard let self = self else { return }
                if let log = log {
                    let logStrings = log.split(separator: "\n")
                    if logStrings.last != "OK-SCRIPT" {
                        let fileredLog = logStrings.filter{ !$0.contains("sudo: unable to resolve host") && !$0.contains("START-SCRIPT") }.reduce("") { $0 + $1 + "\n"}
                        self.view.window?.alert(message: "Error while execute \(name)", informative: fileredLog, delay: 100)
                        print(fileredLog)
                    } else {
                        print("Script \(name) ok")
                        completion()
                    }
                } else {
                    if let error = error {
                        self.view.window?.alert(error: error)
                        print("ERROR: \(String(describing: error))")
                    }
                }
                self.sshCommand.disconnect {}
        }
    }
    
    private func connectGopro3() {
        after(.seconds(1))
        .then {
            Gopro3API.requestData(.getPassword)
        }.then { (passwordData: Data) -> Promise<Void> in
            let password = Gopro3API.getString(from: passwordData.advanced(by: 1)).first!
            Gopro3API.cameraPassword = password
            return Gopro3API.request(.power(on: true))
        }.then {
            return Gopro3API.attempt(retryCount: 10, delay: .seconds(1)) {
                Gopro3API.requestData(.cameraModel)
            }
        }.done { data in
            let model = Gopro3API.getString(from: data.advanced(by: 3))
            self.toolbar?.appendItem(withItemIdentifier: .auxCameraModel)
            DispatchQueue.main.async {
                guard let textField = self.toolbar?.getItem(for: .auxCameraModel)?.view as? NSTextField else { return }
                textField.stringValue = model[1] + "\n" + model[0]
            }
        }.catch {
            self.view.window?.alert(error: $0)
        }
    }

    func ddsDiscovery() {
        ddsListener = DDSDiscoveryListener(port: "8088") { [weak self] (uuidString: String, ipv4: String) in
            guard let uuid = uuidString.split(separator: ":").last else { return }
            self?.discovered[ipv4] = String(uuid)
        }
        do  {
            try ddsListener.start()
        } catch {
            fatalError(error.localizedDescription)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            guard self.discovered.count != 0 else { return }
            self.ddsListener.stop()
            self.timer?.invalidate()
            self.timer = nil
            self.startRTPS()
        }
    }

    
    private func startRTPS() {
        let interfaceAddresses = FastRTPS.getIP4Address()
        print(discovered, interfaceAddresses)
        let remote = discovered.first { $0.key.starts(with: "10.1.1.") } ?? discovered.first!
        FastRTPS.remoteAddress = remote.key
        tridentID = remote.value
        let remoteStripped = remote.key.split(separator: ".").dropLast()
        let localAddress = interfaceAddresses.first { $0.split(separator: ".").dropLast() == remoteStripped } ?? interfaceAddresses.first!
        FastRTPS.localAddress = localAddress
        print("Local address:", localAddress)
        let network = FastRTPS.remoteAddress + "/32"
        FastRTPS.createParticipant(interfaceIPv4: localAddress, networkAddress: network)
        FastRTPS.setPartition(name: self.tridentID!)
    }
    
    func setConnectedState() {
        if let spinner = spinner {
            spinner.isIndeterminate = false
            spinner.removeFromSuperview()
        }
        gridView.isHidden = false
        
        tridentIdLabel.stringValue = tridentID
        localAddressLabel.stringValue = FastRTPS.localAddress
        connectionAddress.stringValue = FastRTPS.remoteAddress
        
        startRefreshDeviceState()
        RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
            .done { (connectionInfo: [ConnectionInfo]) in
            if let ssid = connectionInfo.first(where: {$0.kind == "802-11-wireless" && $0.state == "Activated"})?.ssid {
                self.connectedSSID = ssid
            } else {
                self.connectedSSID = nil
            }
        }.catch {
            self.view.window?.alert(error: $0)
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
        let list: [NSToolbarItem.Identifier] = [
            .goDive,
            .goMaintenance,
            .space,
            .connectWiFi,
        ]

        list.forEach {
            toolbar.appendItem(withItemIdentifier: $0)
            toolbar.getItem(for: $0)?.isEnabled = false
        }
    }
}

// MARK: Externsions
extension DashboardViewController: GetSSIDPasswordProtocol {
    func enteredPassword(ssid: String, password: String) {
        RestProvider.request(MultiTarget(WiFiServiceAPI.connect(ssid: ssid, passphrase: password)))
        .then { _ in
            after(.seconds(2))
        }.then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
        }.done { (connectionInfo: [ConnectionInfo]) in
            if let ssidConnected = connectionInfo.first(where: {$0.kind == "802-11-wireless" && $0.state == "Activated"})?.ssid,
                ssidConnected == ssid {
                self.connectedSSID = ssid
                KeychainService.set(password, key: ssid)
            }
        }.catch {
            self.view.window?.alert(error: $0)
        }
    }
}
