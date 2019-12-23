/////
////  DashboardViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import FastRTPSBridge
import CircularProgress
import Moya
import PromiseKit

class DashboardViewController: NSViewController {
    let stdParticipantList: Set<String> = ["geoserve", "trident-core", "trident-control", "trident-update", "trident-record"]
    var tridentParticipants: Set<String> = []
    var tridentID: String!
    weak var toolbar: NSToolbar?
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
            } else {
                textField.stringValue = NSLocalizedString("Not connected", comment: "")
                wifiItem.label = NSLocalizedString("Connect WiFi", comment: "")
                wifiItem.paletteLabel = NSLocalizedString("Connect WiFi", comment: "")
                wifiItem.toolTip = NSLocalizedString("Connect Trident WiFi", comment: "")
                button.image = NSImage(named: "wifi")!
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

    @IBAction func connectCameraButtonPress(_ sender: Any?) {
        print(#function)
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
            item.isEnabled = false
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
        }.catch { error in
            print(error)
        }
    }
}
