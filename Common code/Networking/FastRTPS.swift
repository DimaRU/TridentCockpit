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

    class func deleteParticipant() {
        FastRTPS.shared.fastRTPSBridge.deleteParticipant()
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

    class func getIP4Address() -> [String: String] {
        return FastRTPSBridge.getIP4Address()
    }
}
