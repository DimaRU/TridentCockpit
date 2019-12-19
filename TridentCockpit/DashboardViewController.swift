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
    var ssid: String?
    weak var toolbar: NSToolbar?
    
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
//        view.window?.toolbar?.isVisible = false
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

    @IBAction func connectWifiButtonPress(_ sender: Any?) {
        print(#function)
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
                print(deviceState)
                self.tridentNetworkAddressLabel.stringValue = deviceState.ipAddress
                return RestProvider.request(MultiTarget(WiFiServiceAPI.connection))
        }.done { connectionInfo in
            print(connectionInfo)
            if let ssid = connectionInfo.first(where: {$0.kind == "802-11-wireless"})?.ssid,
                let textField = self.view.window?.toolbar?.getItem(for: .wifiSSID)?.view as? NSTextField {
                textField.stringValue = ssid
                self.ssid = ssid
            }
        }.catch { error in
            print(error)
        }
        if let toolbar = view.window?.toolbar {
            toolbar.getItem(for: .goDive)?.isEnabled = true
            toolbar.getItem(for: .goMaintenance)?.isEnabled = true
            toolbar.getItem(for: .goPastDives)?.isEnabled = true
            if let wifiItem = toolbar.getItem(for: .connectWiFi) {
                wifiItem.isEnabled = true
                if ssid != nil {
                    wifiItem.image = NSImage(named: "wifi.slash")!
                    wifiItem.label = NSLocalizedString("Disconnect WiFi", comment: "")
                    wifiItem.paletteLabel = NSLocalizedString("Disconnect WiFi", comment: "")
                    wifiItem.toolTip = NSLocalizedString("Disconnect Trident WiFi", comment: "")
                } else {
                    wifiItem.image = NSImage(named: "wifi")!
                    wifiItem.label = NSLocalizedString("Connect WiFi", comment: "")
                    wifiItem.paletteLabel = NSLocalizedString("Connect WiFi", comment: "")
                    wifiItem.toolTip = NSLocalizedString("Connect Trident WiFi", comment: "")
                }
            }
        }
        
        FastRTPS.setPartition(name: tridentID)
    }
    
    private func setupToolbarButtons() {
        guard let toolbar = view.window?.toolbar else { return }
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
        }
    }

}
