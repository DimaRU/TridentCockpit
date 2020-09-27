/////
////  FastRTPS.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

final class FastRTPS {
    static var localAddress: String = ""
    static var localInterface: String = ""
    static var remoteAddress: String = ""
    
    private static let shared = FastRTPS()
    lazy var fastRTPSBridge: FastRTPSBridge = {
        let bridge = FastRTPSBridge.init()
    #if RTPSDEBUG
        bridge.setlogLevel(.warning)
    #else
        bridge.setlogLevel(.error)
    #endif
        return bridge
    }()
    
    class func setRTPSListener(_ delegate: RTPSListenerDelegate?) {
        FastRTPS.shared.fastRTPSBridge.setRTPSListener(delegate: delegate)
    }
    
    class func setRTPSParticipantListener(_ delegate: RTPSParticipantListenerDelegate?) {
        FastRTPS.shared.fastRTPSBridge.setRTPSParticipantListener(delegate: delegate)
    }

    class func createParticipant(name: String, filterAddress: String? = nil) {
        FastRTPS.shared.fastRTPSBridge.createParticipant(name: name, domainID: 0, localAddress: FastRTPS.localAddress, filterAddress: filterAddress)
    }
    
    class func setPartition(name: String) {
        FastRTPS.shared.fastRTPSBridge.setPartition(name: name)
    }

    class func removeParticipant() {
        FastRTPS.shared.fastRTPSBridge.removeParticipant()
    }

    class func registerReader<T: DDSType>(topic: RovReaderTopic, completion: @escaping (T)->Void) {
        FastRTPS.shared.fastRTPSBridge.registerReader(topic: topic, completion: completion)
    }
    
    class func removeReader(topic: RovReaderTopic) {
        FastRTPS.shared.fastRTPSBridge.removeReader(topic: topic)
    }

    class func registerWriter<T: DDSType>(topic: RovWriterTopic, ddsType: T.Type) {
        FastRTPS.shared.fastRTPSBridge.registerWriter(topic: topic, ddsType: ddsType)
    }
    
    class func removeWriter(topic: RovWriterTopic) {
        FastRTPS.shared.fastRTPSBridge.removeWriter(topic: topic)
    }

    class func send<T: DDSType>(topic: RovWriterTopic, ddsData: T) {
        FastRTPS.shared.fastRTPSBridge.send(topic: topic, ddsData: ddsData)
    }

    class func resignAll() {
        FastRTPS.shared.fastRTPSBridge.resignAll()
    }

    /// Get IPV4 addresses of all network interfaces
    /// - Returns: String array with IPV4 addresses with dot notation x.x.x.x
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
