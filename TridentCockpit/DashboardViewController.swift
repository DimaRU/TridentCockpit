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
        view.window?.toolbar?.isVisible = true
    }
    
    override func viewWillDisappear() {
        view.window?.toolbar?.isVisible = false
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
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destinationController = segue.destinationController as? DiveViewController {
            destinationController.vehicleId = tridentID
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
    
}
