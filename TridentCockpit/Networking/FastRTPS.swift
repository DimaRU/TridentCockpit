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
#if DEBUG
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

    class func createParticipant(interfaceIPv4: String? = nil, networkAddress: String? = nil) {
        FastRTPS.shared.fastRTPSBridge?.createRTPSParticipant(withName: "TridentCockpitOSX",
                                                              interfaceIPv4: interfaceIPv4,
                                                              networkAddress: networkAddress)
    }
    
    class func setPartition(name: String) {
        FastRTPS.shared.fastRTPSBridge?.setPartition(name)
    }

    class func stopRTPS() {
        FastRTPS.shared.fastRTPSBridge?.stopRTPS()
        FastRTPS.shared.fastRTPSBridge = nil
    }

    class func registerReader<T: DDSType>(topic: RovReaderTopic, completion: @escaping (T)->Void) {
        let payloadDecoder = PayloadDecoder(topic: topic.rawValue, completion: completion)
        FastRTPS.shared.fastRTPSBridge?.registerReader(withTopicName: topic.rawValue,
                                                      typeName: T.ddsTypeName,
                                                      keyed: T.isKeyed,
                                                      payloadDecoder: payloadDecoder)
    }
    
    class func removeReader(topic: RovReaderTopic) {
        FastRTPS.shared.fastRTPSBridge?.removeReader(withTopicName: topic.rawValue)
    }

    class func registerWriter(topic: RovWriterTopic, ddsType: DDSType.Type) {
        FastRTPS.shared.fastRTPSBridge?.registerWriter(withTopicName: topic.rawValue,
                                                      typeName: ddsType.ddsTypeName,
                                                      keyed: ddsType.isKeyed)
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
            print(error)
        }
    }

    class func resignAll() {
        FastRTPS.shared.fastRTPSBridge?.resignAll()
    }

    class func getIP4Address() -> Set<String> {
        return FastRTPS.shared.fastRTPSBridge?.getIP4Address() as! Set<String>
    }
}
