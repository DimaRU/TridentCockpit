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
    var discovered: [String: String] = [:]
    var connectionInfo: [ConnectionInfo] = []
    var ddsListener: DDSDiscoveryListener!
    private var sshCommand: SSHCommand!
    private var spinner: CircularProgress?
    private var timer: Timer? {
        willSet { timer?.invalidate() }
    }

    var deviceState: DeviceState? {
        didSet {
            guard oldValue != deviceState else { return }
            connectedSSID = connectionInfo.first(where: {$0.kind == "802-11-wireless" && $0.state == "Activated"})?.ssid
            guard let ipAddress = deviceState?.ipAddress else { return }
                let addrs = ipAddress.split(separator: " ")
                if addrs.count >= 2 {
                    tridentNetworkAddressLabel.stringValue = String(addrs.first{ $0.contains("10.1.1.") } ?? "n/a")
                    payloadAddress.stringValue = String(addrs.first{ !$0.contains("10.1.1.") } ?? "n/a")
                    toolbar.getItem(for: .connectCamera)?.isEnabled = true
                } else {
                    tridentNetworkAddressLabel.stringValue = connectedSSID != nil ? "n/a" : String(addrs[0])
                    payloadAddress.stringValue = connectedSSID != nil ? String(addrs[0]) : "n/a"
                    toolbar.getItem(for: .connectCamera)?.isEnabled = false
                }
            
        }
    }
    var connectedSSID: String? = "\nnot existed\n" {
        didSet {
            guard connectedSSID != oldValue else { return }
            guard let wifiItem = toolbar.getItem(for: .connectWiFi),
                let button = wifiItem.view as? NSButton else { return }
            if connectedSSID != nil {
                ssidLabel.stringValue = self.connectedSSID!
//                toolbar.getItem(for: .connectCamera)?.isEnabled = true
                
                wifiItem.label = NSLocalizedString("Disconnect", comment: "")
                wifiItem.toolTip = NSLocalizedString("Disconnect Trident WiFi", comment: "")
                button.image = NSImage(named: "wifi.slash")!
                if payloadAddress.stringValue == "n/a" {
                    payloadAddress.stringValue = "waiting..."
                }
            } else {
                ssidLabel.stringValue = "not connected"
                cameraModelLabel.stringValue = "n/a"
                cameraFirmwareLabel.stringValue = "n/a"
                payloadAddress.stringValue = "n/a"
                Gopro3API.cameraPassword = nil
                toolbar.getItem(for: .connectCamera)?.isEnabled = false

                wifiItem.label = NSLocalizedString("Connect", comment: "")
                wifiItem.toolTip = NSLocalizedString("Connect Trident WiFi", comment: "")
                button.image = NSImage(named: "wifi")!
                Gopro3API.cameraPassword = nil
            }
        }
    }

    
    // MARK: Outlets
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet weak var gridView: NSGridView!
    @IBOutlet weak var tridentIdLabel: NSTextField!
    @IBOutlet weak var connectionAddress: NSTextField!
    @IBOutlet weak var tridentNetworkAddressLabel: NSTextField!
    @IBOutlet weak var localAddressLabel: NSTextField!
    @IBOutlet weak var ssidLabel: NSTextField!
    @IBOutlet weak var payloadAddress: NSTextField!
    @IBOutlet weak var cameraModelLabel: NSTextField!
    @IBOutlet weak var cameraFirmwareLabel: NSTextField!
    
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gridView.isHidden = true
        parent?.view.wantsLayer = true
        parent?.view.layer?.contents = NSImage(named: "Trident")
        spinner = addCircularProgressView(to: view)
        setupNotifications()
        ddsDiscoveryStart()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        if view.window?.toolbar == nil {
            let wifiItem = toolbar.getItem(for: .connectWiFi)
            let button = wifiItem?.view as? NSButton
            // hack!!!
            button?.image = NSImage(named: "wifi.slash")!
            button?.image = NSImage(named: "wifi")!
        }
        view.window?.toolbar = toolbar
        toolbar.isVisible = true
        
        if FastRTPS.remoteAddress != "" {
            startRefreshDeviceState()
        } else {
            toolbar.items.forEach{ $0.isEnabled = false }
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        timer = nil
    }
    
    // MARK: Actions
    @IBAction func goDiveScreen(_ sender: Any?) {
        self.toolbar.isVisible = false
        let diveViewController: DiveViewController = DiveViewController.instantiate()
        diveViewController.vehicleId = tridentID
        transition(to: diveViewController, options: .slideUp) {
            self.toolbar.isVisible = false
        }
    }

    @IBAction func goMaintenanceScreen(_ sender: Any?) {
        let maintenanceViewController: MaintenanceViewController = MaintenanceViewController.instantiate()
        transition(to: maintenanceViewController, options: .slideLeft)
    }

    @IBAction func goPastDivesScreen(_ sender: Any?) {
        let pastDivesViewController: PastDivesViewController = PastDivesViewController.instantiate()
        transition(to: pastDivesViewController, options: .slideLeft)
    }

    @IBAction func connectWifiButtonPress(_ sender: Any?) {
        guard let button = sender as? NSButton else { return }
        if connectedSSID == nil {
            connectWiFi(view: button.superview!)
        } else {
            disconnectWiFi()
        }
    }

    @IBAction func connectCameraButtonPress(_ sender: Any?) {
        guard let ipAddress = deviceState?.ipAddress, ipAddress.split(separator: " ").count == 2 else { return }
        executeScript(name: "PayloadProvision") {
            self.connectGopro3()
        }
    }

    // MARK: Private func
    private func addCircularProgressView(to view: NSView) -> CircularProgress {
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
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
            .done { (connectionInfo: [ConnectionInfo]) in
                    self.connectionInfo = connectionInfo
            }.then {
                RestProvider.request(MultiTarget(ResinAPI.deviceState))
            }.done { (deviceState: DeviceState) in
                self.deviceState = deviceState
            }.catch { error in
                switch error {
                case NetworkError.unaviable(let message):
                    self.timer = nil
                    self.view.window?.alert(message: "Trident connection lost", informative: message, delay: 4)
                default:
                    self.view.window?.alert(error: error, delay: 5)
                }
            }
        }
    }
    
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
        let redirectPorts = Gopro3API.redirectPorts
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
            self.cameraModelLabel.stringValue = model[1]
            self.cameraFirmwareLabel.stringValue = model[0]
        }.catch {
            self.view.window?.alert(error: $0)
        }
    }

    private func ddsDiscoveryStart() {
        discovered = [:]
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
        
    // MARK: Internal func
    func setDisconnectedState() {
        timer = nil
        
        let message = "Trident disconnected"
        if let otherViewController = self.parent?.children.first(where: { $0 != self}) {
            let info: String
            switch otherViewController {
            case is DiveViewController:
                info = "Connection to Trident lost. Exiting Pilot Mode."
            case is MaintenanceViewController:
                info = "Connection to Trident lost. Exiting Maintenance Mode."
            case is PastDivesViewController:
                info = "Connection to Trident lost. Exiting Past Dives Mode."
            default:
                fatalError()
            }
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = info
            alert.alertStyle = .warning
            alert.beginSheetModal(for: otherViewController.view.window!) { responce in
                otherViewController.transitionBack(options: .crossfade)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak alert] in
                guard let alert = alert else { return }
                otherViewController.view.window!.endSheet(alert.window, returnCode: .cancel)
            }
            
        }
        FastRTPS.deleteParticipant()
        toolbar.items.forEach{ $0.isEnabled = false }
        connectedSSID = nil
        gridView.isHidden = true
        view.layer?.backgroundColor = nil
        spinner = addCircularProgressView(to: view)
        ddsDiscoveryStart()
    }
    
    func setConnectedState() {
        if let spinner = spinner {
            spinner.isIndeterminate = false
            spinner.removeFromSuperview()
        }
        
        view.layer?.backgroundColor = NSColor(named: "splashColor")!.cgColor
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
}

// MARK: Externsions
extension DashboardViewController: WiFiPopupProtocol {
    func enteredPassword(ssid: String, password: String) {
        timer = nil
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
            self.connectionInfo = connectionInfo
            self.startRefreshDeviceState()
        }.catch {
            self.view.window?.alert(error: $0)
        }
    }
}
