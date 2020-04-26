/////
////  DashboardViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import FastRTPSBridge
import Moya
import PromiseKit
import Shout

class DashboardViewController: UIViewController, RTPSConnectionMonitorProtocol {
    var tridentID: String!
    var discovered: [String: (uuid: String, interface: String, isWiFi: Bool)] = [:]
    var ddsListener: DDSDiscoveryListener!
    private var spinner: SwiftSpinner?
    private var connectionMonitor = RTPSConnectionMonitor()
    private var timer: Timer? {
        willSet { timer?.invalidate() }
    }
    
    private var connectedThruBuoy: Bool? = nil {
        didSet {
            guard connectedThruBuoy != nil else {
                connectedThru.text = "n/a"
                return
            }
            connectedThru.text = connectedThruBuoy! ? "topside buoy" : "onboard WiFi"
        }
    }
    private var wifiConnected = false

    var connectionInfo: [ConnectionInfo] = [] {
        didSet {
            let connectionCount = connectionInfo.filter{ $0.state == "Activated" }.count
            guard connectionCount != 0 else {
                connectedThruBuoy = nil
                wifiConnected = false
                ssidLabel.text = "not connected"
                wifiMode.text = "n/a"
                navigationItem.getItem(for: .connectCamera)?.isEnabled = false
                cameraModelLabel.text = "n/a"
                cameraFirmwareLabel.text = "n/a"
                return
            }
            guard connectionInfo != oldValue else { return }
            guard let wifiItem = navigationItem.getItem(for: .connectWiFi) else { return }

            if let wifiConnection = connectionInfo.first(where: {$0.kind == "802-11-wireless" && $0.state == "Activated"}) {
                wifiConnected = true
                ssidLabel.text = wifiConnection.ssid
                wifiMode.text = wifiConnection.mode
                wifiItem.image = UIImage(systemName: "wifi.slash")

                if connectionCount == 1 {
                    connectedThruBuoy = false
                    navigationItem.getItem(for: .connectCamera)?.isEnabled = false
                    cameraModelLabel.text = "n/a"
                    cameraFirmwareLabel.text = "n/a"
                } else {
                    if FastRTPS.remoteAddress.contains("10.1.1.") {
                        connectedThruBuoy = true
                        navigationItem.getItem(for: .connectCamera)?.isEnabled = true
                    } else {
                        connectedThruBuoy = false
                        navigationItem.getItem(for: .connectCamera)?.isEnabled = false
                        cameraModelLabel.text = "n/a"
                        cameraFirmwareLabel.text = "n/a"
                    }
                }
                
            } else {
                // No wifi conn
                wifiConnected = false
                connectedThruBuoy = true
                ssidLabel.text = "not connected"
                wifiMode.text = "n/a"
                wifiItem.image = UIImage(systemName: "wifi")
                Gopro3API.cameraPassword = nil
                navigationItem.getItem(for: .connectCamera)?.isEnabled = false
                cameraModelLabel.text = "n/a"
                cameraFirmwareLabel.text = "n/a"
            }
        }
    }

    
    // MARK: Outlets
    @IBOutlet weak var tridentIdLabel: UILabel!
    @IBOutlet weak var imageVersionLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var connectedThru: UILabel!
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var wifiMode: UILabel!
    @IBOutlet weak var cameraModelLabel: UILabel!
    @IBOutlet weak var cameraFirmwareLabel: UILabel!
    
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.contentsGravity = .resizeAspectFill
        connectionMonitor.delegate = self
        connectionMonitor.startNotifications()
        appVersionLabel.text = "\(Bundle.main.versionNumber ?? "") (\(Bundle.main.buildNumber ?? ""))"
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
        if !wifiConnected {
            connectWiFi(view: sender.view!)
        } else {
            disconnectWiFi()
        }
    }

    @IBAction func connectCameraButtonPress(_ sender: UIBarButtonItem) {
        connectGopro3()
    }

    // MARK: Private func
    // MARK: Interface
    private func hideInterface() {
        navigationItem.leftBarButtonItems?.forEach{ $0.isEnabled = false }
        connectionInfo = []
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
    
    private func alertNetwork(error: Error, delay: Int = 5) {
        if !connectionMonitor.isConnected {
            // Drop timeout errors
            switch error {
            case NetworkError.unaviable:
                return
            default:
                print(#function, error)
            }
        }
        error.alert(delay: delay)
    }

    // MARK: Network
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
            self.startRefreshDeviceState()
        }.catch {
            self.alertNetwork(error: $0)
        }
    }
    
    private func disconnectWiFi() {
        SSH.executeScript(name: "PayloadCleanup")
        .then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.disconnect))
        }.then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.clear))
        }.catch {
            self.alertNetwork(error: $0)
        }
    }

    private func connectWiFi(view: UIView) {
        RestProvider.request(MultiTarget(WiFiServiceAPI.scan))
        .then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.ssids))
        }.done { (ssids: [SSIDInfo]) -> Void in
            self.showPopup(with: ssids.filter{!$0.ssid.contains("Trident-")}, view: view)
        }.catch {
            self.alertNetwork(error: $0)
        }
    }

    private func connectGopro3() {
        SSH.executeScript(name: "PayloadProvision")
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
        }.catch {
            self.alertNetwork(error: $0)
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
        
        if let currentViewController = presentedViewController ?? navigationController?.topViewController,
            !(currentViewController is UIAlertController) {
            
            func disconnectProc() {
                print(#function, currentViewController)
                guard currentViewController != self else {
                    self.hideInterface()
                    self.addCircularProgressView(to: self.view)
                    self.ddsDiscoveryStart()
                    return
                }
                if self.presentedViewController != nil {
                    currentViewController.dismiss(animated: true)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            
            let info: String
            switch currentViewController {
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
                disconnectProc()
            }
            alert.addAction(action)
            currentViewController.present(alert, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak alert] in
                alert?.dismiss(animated: true) {
                    disconnectProc()
                }
            }
        } else {
            assertionFailure("Disconnect wrong controller")
        }
        
        FastRTPS.deleteParticipant()
    }
    
    func rtpsConnectedState() {
        spinner?.hide {
            self.spinner = nil
        }
        showInterface()
        
        tridentIdLabel.text = tridentID
        FastRTPS.setPartition(name: tridentID)

        firstly {
            self.checkTridentFirmwareVersion()
        }.then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
        }.done { (connectionInfo: [ConnectionInfo]) in
            self.connectionInfo = connectionInfo
        }.then {
            self.checkWifiServiceVersion()
        }.catch {
            self.alertNetwork(error: $0)
        }
        
        startRefreshDeviceState()
        navigationItem.getItem(for: .connectWiFi)?.isEnabled = true
    }
    
    private func checkTridentFirmwareVersion() -> Promise<Void> {
        return RestProvider.request(MultiTarget(ResinAPI.latestRelease))
            .then { (latestRelease: [String:String]) in
                RestProvider.request(MultiTarget(ResinAPI.imageVersion)).map { ($0, latestRelease) }
            }.done { (imageVersion: [String:String], latestRelease: [String:String]) in
                let currentImageVersion = imageVersion["version"] ?? "11.11.11"
                if let commit = latestRelease["commit"]?.prefix(6) {
                    self.imageVersionLabel.text = currentImageVersion + " (\(commit))"
                } else {
                    self.imageVersionLabel.text = currentImageVersion
                }
                let targetImageVersion = GlobalParams.targetImageVersion
                let message: String
                switch targetImageVersion.compare(currentImageVersion, options: .numeric) {
                case .orderedAscending:
                    message = "New Trident image version. Some functions may not work. Please update Trident Cockpit app."
                case .orderedDescending:
                    message = "Old Trident image version. Some functions may not work. Please update Trident."
                case .orderedSame:
                    return
                }
                let informative = "Version " + currentImageVersion + ", expected " + targetImageVersion
                alert(message: message, informative: informative, delay: 20)
        }
    }

    private func checkWifiServiceVersion() -> Promise<Void> {
        return SSH.executeCommand("dpkg-query -s nm-wifi-service|grep Version")
        .done { log in
            let version = log.first!.split(separator: " ").last!
            print(version)
            if version.compare("1.0.5-1", options: .numeric) == .orderedDescending {
                print("nm-wifi-service version ok, enable set ap")
            }
        }
    }
}

// MARK: Externsions
extension DashboardViewController: WiFiPopupProtocol {
    func enteredPassword(ssid: String, password: String) {
        timer = nil
        RestProvider.request(MultiTarget(WiFiServiceAPI.connect(ssid: ssid, passphrase: password)))
        .then { _ in
            after(.seconds(1))
        }.then {
            RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
        }.done { (connectionInfo: [ConnectionInfo]) in
            if let ssidConnected = connectionInfo.first(where: {$0.kind == "802-11-wireless" && $0.state == "Activated"})?.ssid,
                ssidConnected == ssid {
                KeychainService.set(password, key: ssid)
            }
            self.connectionInfo = connectionInfo
            self.startRefreshDeviceState()
        }.catch {
            self.alertNetwork(error: $0)
        }
    }
}
