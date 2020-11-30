/////
////  FastRTPS.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift
import CDRCodable

final class FastRTPS {
    static var localAddress: String = ""
    static var localInterface: String = ""
    static var remoteAddress: String = ""
    
    private static let shared = FastRTPS()
    lazy var fastRTPSSwift: FastRTPSSwift = {
        let bridge = FastRTPSSwift.init()
        print("Fast-DDS version:", FastRTPSSwift.fastDDSVersion())
    #if RTPSDEBUG
        bridge.setlogLevel(.warning)
    #else
        bridge.setlogLevel(.warning)
    #endif
        return bridge
    }()
    
    class func setRTPSListener(_ delegate: RTPSListenerDelegate?) {
        FastRTPS.shared.fastRTPSSwift.setRTPSListener(delegate: delegate)
    }
    
    class func setRTPSParticipantListener(_ delegate: RTPSParticipantListenerDelegate?) {
        FastRTPS.shared.fastRTPSSwift.setRTPSParticipantListener(delegate: delegate)
    }

    class func createParticipant(name: String, filterAddress: String? = nil) {
        try! FastRTPS.shared.fastRTPSSwift.createParticipant(name: name, domainID: 0, localAddress: FastRTPS.localAddress, remoteWhitelistAddress: filterAddress)
    }
    
    class func setPartition(name: String) {
        FastRTPS.shared.fastRTPSSwift.setPartition(name: name)
    }

    class func removeParticipant() {
        FastRTPS.shared.fastRTPSSwift.removeParticipant()
    }

    class func registerReader<T: DDSType>(topic: RovReaderTopic, completion: @escaping (T)->Void) {
        try! FastRTPS.shared.fastRTPSSwift.registerReaderRaw(topic: topic, ddsType: T.self, ipv4Locator: nil) { (_, data) in
            let decoder = CDRDecoder()
            do {
                let t = try decoder.decode(T.self, from: data)
                completion(t)
            } catch {
                print(topic.rawValue, error)
            }
        }
    }
    
    class func removeReader(topic: RovReaderTopic) {
        try! FastRTPS.shared.fastRTPSSwift.removeReader(topic: topic)
    }

    class func registerWriter<T: DDSType>(topic: RovWriterTopic, ddsType: T.Type) {
        try! FastRTPS.shared.fastRTPSSwift.registerWriter(topic: topic, ddsType: ddsType)
    }
    
    class func removeWriter(topic: RovWriterTopic) {
        try! FastRTPS.shared.fastRTPSSwift.removeWriter(topic: topic)
    }

    class func send<T: DDSType>(topic: RovWriterTopic, ddsData: T) {
        try! FastRTPS.shared.fastRTPSSwift.send(topic: topic, ddsData: ddsData)
    }

    class func resignAll() {
        FastRTPS.shared.fastRTPSSwift.resignAll()
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
