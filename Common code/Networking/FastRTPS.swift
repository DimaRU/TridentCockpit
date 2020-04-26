/////
////  FastRTPS.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import CDRCodable
import FastRTPSBridge

final class FastRTPS {
    var localIPAddress: String = ""
    var remoteIPAddress: String = ""
    
    private static let shared = FastRTPS()
#if RTPSDEBUG
    lazy var fastRTPSBridge: FastRTPSBridge? = FastRTPSBridge.init(logLevel: .warning)
#else
    lazy var fastRTPSBridge: FastRTPSBridge? = FastRTPSBridge.init(logLevel: .error)
#endif
    
    class var localAddress: String {
        get { FastRTPS.shared.localIPAddress }
        set { FastRTPS.shared.localIPAddress = newValue }
    }

    class var remoteAddress: String {
        get { FastRTPS.shared.remoteIPAddress }
        set { FastRTPS.shared.remoteIPAddress = newValue }
    }

    class func createParticipant(name: String, interfaceIPv4: String? = nil, networkAddress: String? = nil) {
        FastRTPS.shared.fastRTPSBridge?.createRTPSParticipant(withName: name,
                                                              interfaceIPv4: interfaceIPv4,
                                                              networkAddress: networkAddress)
    }
    
    class func setPartition(name: String) {
        FastRTPS.shared.fastRTPSBridge?.setPartition(name)
    }

    class func deleteParticipant() {
        FastRTPS.shared.fastRTPSBridge?.deleteParticipant()
        FastRTPS.shared.localIPAddress = ""
        FastRTPS.shared.remoteIPAddress = ""
    }

    class func registerReader<T: DDSType>(topic: RovReaderTopic, completion: @escaping (T)->Void) {
        let payloadDecoder = PayloadDecoder(topic: topic.rawValue, completion: completion)
        FastRTPS.shared.fastRTPSBridge?.registerReader(withTopicName: topic.rawValue,
                                                      typeName: T.ddsTypeName,
                                                      keyed: T.isKeyed,
                                                      transientLocal: topic.transientLocal,
                                                      reliable: topic.reliable,
                                                      payloadDecoder: payloadDecoder)
    }
    
    class func removeReader(topic: RovReaderTopic) {
        FastRTPS.shared.fastRTPSBridge?.removeReader(withTopicName: topic.rawValue)
    }

    class func registerWriter(topic: RovWriterTopic, ddsType: DDSType.Type) {
        FastRTPS.shared.fastRTPSBridge?.registerWriter(withTopicName: topic.rawValue,
                                                      typeName: ddsType.ddsTypeName,
                                                      keyed: ddsType.isKeyed,
                                                      transientLocal: topic.transientLocal)
    }
    class func removeWriter(topic: RovWriterTopic) {
        FastRTPS.shared.fastRTPSBridge?.removeWriter(withTopicName: topic.rawValue)
    }

    class func send<T: DDSType>(topic: RovWriterTopic, ddsData: T) {
        let encoder = CDREncoder()
        do {
            let data = try encoder.encode(ddsData)
            if let key = (ddsData as? DDSKeyed)?.key {
                FastRTPS.shared.fastRTPSBridge?.send(withTopicName: topic.rawValue, data: data, key: key)
            } else {
                FastRTPS.shared.fastRTPSBridge?.send(withTopicName: topic.rawValue, data: data)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    class func resignAll() {
        FastRTPS.shared.fastRTPSBridge?.resignAll()
    }

    class func getIP4Address() -> [String: String] {
        var localIP: [String: String] = [:]

        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else { return localIP }
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name: String = String(cString: (interface!.ifa_name))
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                let address = String(cString: hostname)
                localIP[name] = address
            }
        }
        freeifaddrs(ifaddr)
        
        return localIP
    }
}
