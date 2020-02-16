/////
////  UDPListener.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import Network

class DDSDiscoveryListener {
    private let queueName = Bundle.main.bundleIdentifier! + ".ddsDiscovery"
    var delegate: ((String, String)->Void)?
    var port: String
    private var listener: NWListener?
    private var connection: NWConnection?
    
    init(port: String, delegate: @escaping ((String, String)->Void)) {
        self.delegate = delegate
        self.port = port
    }
    
    func start() throws {
        let listener = try NWListener(using: .udp, on: NWEndpoint.Port(port)!)
        self.listener = listener
        listener.stateUpdateHandler = self.listenerStateDidChange(to:)
        listener.newConnectionHandler = self.didAccept(connection:)
        listener.start(queue: .init(label: queueName))
    }
    
    private func listenerStateDidChange(to newState: NWListener.State) {
        switch newState {
        case .setup,
             .waiting,
             .ready,
             .cancelled:
            break
        case .failed(let error):
            print("NWListener fail", error)
        @unknown default:
            fatalError()
        }
    }

    private func didAccept(connection: NWConnection) {
        self.connection = connection
        connection.receiveMessage { [weak self] (data, contentContext, isComplete, error) in
            if let data = data,
                case NWEndpoint.hostPort(let host, _) = connection.endpoint,
                case NWEndpoint.Host.ipv4(let address) = host {
                let r = address.rawValue
                let ipv4 = "\(r[0]).\(r[1]).\(r[2]).\(r[3])"
                self?.delegate?(String(data: data, encoding: .ascii) ?? "", ipv4)
            }
            if let error = error {
                print("NWConnection error:", error)
            }
            connection.cancel()
            self?.connection = nil
        }
        connection.start(queue: .init(label: queueName))
    }
    
    func stop() {
        connection?.cancel()
        connection = nil
        listener?.cancel()
        listener = nil
    }
}
