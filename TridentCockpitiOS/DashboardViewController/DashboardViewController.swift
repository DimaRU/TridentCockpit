/////
////  DashboardViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import FastRTPSBridge
import Moya
import PromiseKit
import SwiftSH

class DashboardViewController: UIViewController, RTPSConnectionMonitorProtocol {
    var tridentID: String!
    var discovered: [String: (uuid: String, interface: String, isWiFi: Bool)] = [:]
    var connectionInfo: [ConnectionInfo] = []
    var ddsListener: DDSDiscoveryListener!
    private var spinner: SwiftSpinner?
    private var connectionMonitor = RTPSConnectionMonitor()
    private var sshCommand: SSHCommand!
    private var timer: Timer? {
        willSet { timer?.invalidate() }
    }

    var deviceState: DeviceState? {
        didSet {
            if deviceState == nil {
                connectedSSID = nil
                tridentNetworkAddressLabel.text = "n/a"
                payloadAddress.text = "n/a"
                navigationItem.getItem(for: .connectCamera)?.isEnabled = false
            }
            guard oldValue != deviceState, deviceState != nil else { return }
            connectedSSID = connectionInfo.first(where: {$0.kind == "802-11-wireless" && $0.state == "Activated"})?.ssid
            guard let ipAddress = deviceState?.ipAddress else { return }
                let addrs = ipAddress.split(separator: " ")
                if addrs.count > 1 {
                    tridentNetworkAddressLabel.text = String(addrs.first{ $0.contains("10.1.1.") } ?? "n/a")
                    payloadAddress.text = String(addrs.first{ !$0.contains("10.1.1.") } ?? "n/a")
                    navigationItem.getItem(for: .connectCamera)?.isEnabled = true
                } else {
                    tridentNetworkAddressLabel.text = connectedSSID != nil ? "n/a" : String(addrs[0])
                    payloadAddress.text = connectedSSID != nil ? String(addrs[0]) : "n/a"
                    navigationItem.getItem(for: .connectCamera)?.isEnabled = false
                }
            
        }
    }
    var connectedSSID: String? = "\nnot existed\n" {
        didSet {
            guard let wifiItem = navigationItem.getItem(for: .connectWiFi) else { return }
            if connectedSSID == nil {
                ssidLabel.text = "not connected"
                cameraModelLabel.text = "n/a"
                cameraFirmwareLabel.text = "n/a"
                payloadAddress.text = "n/a"
                Gopro3API.cameraPassword = nil

                wifiItem.image = UIImage(systemName: "wifi")
                Gopro3API.cameraPassword = nil
                return
            }
            guard connectedSSID != oldValue else { return }
            ssidLabel.text = self.connectedSSID!
            
            wifiItem.image = UIImage(systemName: "wifi.slash")
            if payloadAddress.text == "n/a" {
                payloadAddress.text = "waiting..."
            }
        }
    }

    
    // MARK: Outlets
    @IBOutlet weak var tridentIdLabel: UILabel!
    @IBOutlet weak var connectionAddress: UILabel!
    @IBOutlet weak var tridentNetworkAddressLabel: UILabel!
    @IBOutlet weak var localAddressLabel: UILabel!
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var payloadAddress: UILabel!
    @IBOutlet weak var cameraModelLabel: UILabel!
    @IBOutlet weak var cameraFirmwareLabel: UILabel!
    
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.contentsGravity = .resizeAspectFill
        connectionMonitor.delegate = self
        connectionMonitor.startNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layer.contents = UIImage(named: "Trident")?.cgImage

        if FastRTPS.remoteAddress != "", connectionMonitor.isConnected {
            startRefreshDeviceState()
        } else {
            hideInterface()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if FastRTPS.remoteAddress == "" || !connectionMonitor.isConnected {
            addCircularProgressView(to: view)
            ddsDiscoveryStart()
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.layer.contents = nil       // save memory
    }
    
    // MARK: Actions
    @IBSegueAction
    private func goDiveScreen(coder: NSCoder) -> DiveViewController? {
        return DiveViewController(coder: coder, vehicleId: tridentID)
    }
    
    @IBAction func connectWifiButtonPress(_ sender: UIBarButtonItem) {
        if connectedSSID == nil {
            connectWiFi(view: sender.view!)
        } else {
            disconnectWiFi()
        }
    }

    @IBAction func connectCameraButtonPress(_ sender: UIBarButtonItem) {
        guard let ipAddress = deviceState?.ipAddress, ipAddress.split(separator: " ").count == 2 else { return }
        executeScript(name: "PayloadProvision") {
            self.connectGopro3()
        }
    }

    // MARK: Private func
    private func hideInterface() {
        navigationItem.leftBarButtonItems?.forEach{ $0.isEnabled = false }
        connectedSSID = nil
        deviceState = nil
        navigationController?.navigationBar.isHidden = true
        view.subviews.forEach{ $0.isHidden = true }
    }
    
    private func showInterface() {
        navigationController?.navigationBar.isHidden = false
        view.subviews.forEach{ $0.isHidden = false }
    }
    
    private func addCircularProgressView(to view: UIView) {
        let width = traitCollection.verticalSizeClass == .compact ? 170 : 200
        spinner = SwiftSpinner(frame: CGRect(x: 0, y: 0, width: width, height: width))
        spinner?.showBlurBackground = false
        spinner?.titleLabel.textColor = .black
        let fontSize: CGFloat = traitCollection.verticalSizeClass == .compact ? 17 : 22
        let font = UIFont.systemFont(ofSize: fontSize)
        spinner?.setTitleFont(font)
        spinner?.outerColor = .systemTeal
        spinner?.innerColor = .lightGray
        spinner?.show(in: view, title: "Searching\nfor Trident")
     }

    private func startRefreshDeviceState() {
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.refreshDeviceState()
        }
    }
    
    private func refreshDeviceState() {
        RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
            .done { (connectionInfo: [ConnectionInfo]) in
                self.connectionInfo = connectionInfo
        }.then {
            RestProvider.request(MultiTarget(ResinAPI.deviceState))
        }.done { (deviceState: DeviceState) in
            self.deviceState = deviceState
            self.startRefreshDeviceState()
        }.catch { error in
            switch error {
            case NetworkError.unaviable(let message):
                self.timer = nil
                alert(message: "Trident connection lost", informative: message, delay: 5)
            default:
                error.alert(delay: 5)
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
            $0.alert()
        }
    }

    private func connectWiFi(view: UIView) {
        RestProvider.request(MultiTarget(WiFiServiceAPI.scan))
        .then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.ssids))
        }.done { (ssids: [SSIDInfo]) -> Void in
            self.showPopup(with: ssids.filter{!$0.ssid.contains("Trident-")}, view: view)
        }.catch {
            $0.alert()
        }
    }

    private func showPopup(with ssids: [SSIDInfo], view: UIView) {
        let controller: WiFiPopupViewController = WiFiPopupViewController()
        controller.delegate = self
        controller.ssids = ssids
        controller.modalPresentationStyle = .popover
        let popover = controller.popoverPresentationController
        popover?.sourceView = view
        popover?.sourceRect = view.frame
        present(controller, animated: true)
    }

    private func executeScript(name: String, completion: @escaping (() -> Void)) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "sh") else { return }
        guard let scriptBody = try? String(contentsOf: url) else { return }
        
        let basePort = GlobalParams.basePort
        let redirectPorts = Gopro3API.redirectPorts
        let login = GlobalParams.rovLogin
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        
        var header = "#/bin/bash\n"
        header += "echo \(password) | sudo -S echo START-SCRIPT\n"
        header += "exec 2>&1\n"
        header += "SOURCEIP=\(FastRTPS.localAddress)\n"
        header += "BASEPORT=\(basePort)\n"
        header += "REDIRECTPORTS=(\(redirectPorts))\n"
        sshCommand = try! SSHCommand(host: FastRTPS.remoteAddress)
        sshCommand.log.level = .error
        sshCommand.timeout = 10

        sshCommand.connect()
            .authenticate(.byPassword(username: login, password: password))
            .execute(header+scriptBody) { [weak self] (command, log: String?, error) in
                guard let self = self else { return }
                if let log = log {
                    let logStrings = log.split(separator: "\n")
                    if logStrings.last != "OK-SCRIPT" {
                        let fileredLog = logStrings.filter{ !$0.contains("sudo: unable to resolve host") && !$0.contains("START-SCRIPT") }.reduce("") { $0 + $1 + "\n"}
                        alert(message: "Error while execute \(name)", informative: fileredLog, delay: 100)
                        print(fileredLog)
                    } else {
                        print("Script \(name) ok")
                        completion()
                    }
                } else {
                    error?.alert()
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
            self.cameraModelLabel.text = model[1]
            self.cameraFirmwareLabel.text = model[0]
        }.catch { error in
            error.alert()
        }
    }

    private func ddsDiscoveryStart() {
        discovered = [:]
        ddsListener = DDSDiscoveryListener(port: "8088") { [weak self] (uuidString: String, ipv4: String, interface: String, isWiFi: Bool) in
            guard let uuid = uuidString.split(separator: ":").last else { return }
            self?.discovered[ipv4] = (uuid: String(uuid), interface: interface, isWiFi: isWiFi)
        }
        do  {
            try ddsListener.start()
        } catch {
            fatalError(error.localizedDescription)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard self.discovered.count != 0 else { return }
            self.timer = nil
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                self.ddsListener.stop()
                self.startRTPS()
            }
        }
    }

    private func checkTridentFirmwareVersion() {
        RestProvider.request(MultiTarget(ResinAPI.imageVersion))
            .done { (imageVersion: [String:String]) in
                let firmwareVersion = GlobalParams.firmwareVersion
                let currentFirmwareVersion = imageVersion["version"] ?? "0.0.0"
                if currentFirmwareVersion != firmwareVersion {
                    let message = "Incompatible Trident firmware version. Some functions may not work."
                    let informative = "Version " + currentFirmwareVersion + ", expected " + firmwareVersion
                    alert(message: message, informative: informative, delay: 20)
                }
        }.catch {
            $0.alert(delay: 20)
        }
    }

    private func startRTPS() {
        let interfaceAddresses = FastRTPS.getIP4Address()
        print(discovered, interfaceAddresses)
        let remote = discovered.first { $0.value.isWiFi } ?? discovered.first!
        FastRTPS.remoteAddress = remote.key
        tridentID = remote.value.uuid
        let localAddress = interfaceAddresses[remote.value.interface]!
        FastRTPS.localAddress = localAddress
        print("Local address:", localAddress)
        let network = FastRTPS.remoteAddress + "/32"
        FastRTPS.createParticipant(name: "TridentCockpitiOS", interfaceIPv4: localAddress, networkAddress: network)
        FastRTPS.setPartition(name: self.tridentID!)
    }
        
    // MARK: Internal func
    func rtpsDisconnectedState() {
        timer = nil
        let message = "Trident disconnected"
        if let otherViewController = presentedViewController ?? navigationController?.topViewController,
            !(otherViewController is UIAlertController) {
            let info: String
            switch otherViewController {
            case is DiveViewController:
                info = "Connection to Trident lost. Exiting Pilot Mode."
            case is MaintenanceViewController:
                info = "Connection to Trident lost. Exiting Maintenance Mode."
            case is PastDivesViewController:
                info = "Connection to Trident lost. Exiting Past Dives Mode."
            case self:
                info = "Connection to Trident lost."
            default:
                fatalError()
            }
            let alert = UIAlertController(title: message, message: info, preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .cancel) { _ in
                guard otherViewController != self else { return }
                if self.presentedViewController != nil {
                    otherViewController.dismiss(animated: true)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            alert.addAction(action)

            otherViewController.present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { //[weak alert] in
//                guard let alert = alert else { return }
                alert.dismiss(animated: true) {
                    guard otherViewController != self else {
                        self.hideInterface()
                        self.addCircularProgressView(to: self.view)
                        self.ddsDiscoveryStart()
                        return
                    }
                    if self.presentedViewController != nil {
                        otherViewController.dismiss(animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
        FastRTPS.deleteParticipant()
        
    }
    
    func rtpsConnectedState() {
        spinner?.hide {
            self.spinner = nil
        }
        showInterface()
        
        tridentIdLabel.text = tridentID
        localAddressLabel.text = FastRTPS.localAddress
        connectionAddress.text = FastRTPS.remoteAddress
        
        checkTridentFirmwareVersion()
        
        startRefreshDeviceState()
        RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
            .done { (connectionInfo: [ConnectionInfo]) in
            if let ssid = connectionInfo.first(where: {$0.kind == "802-11-wireless" && $0.state == "Activated"})?.ssid {
                self.connectedSSID = ssid
            } else {
                self.connectedSSID = nil
            }
        }.catch {
            $0.alert()
        }
        navigationItem.getItem(for: .connectWiFi)?.isEnabled = true
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
            $0.alert()
        }
    }
}
