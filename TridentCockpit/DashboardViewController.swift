/////
////  DashboardViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import FastRTPSBridge

class DashboardViewController: NSViewController {
    let stdParticipantList: Set<String> = ["geoserve", "trident-core", "trident-control", "trident-update", "trident-record"]
    var tridentParticipants: Set<String> = []
    var tridentID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        view.window?.title = tridentID
        if let toolbar = view.window?.toolbar {
            toolbar.getItem(for: .goDive)?.isEnabled = true
            toolbar.getItem(for: .goMaintenance)?.isEnabled = true
            toolbar.getItem(for: .goPastDives)?.isEnabled = true
            toolbar.getItem(for: .connectWiFi)?.isEnabled = true
        }
    }
    
}
