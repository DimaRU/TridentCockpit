/////
////  RTPSConnectionMonitor.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

protocol RTPSConnectionMonitorProtocol: AnyObject {
    func rtpsConnectedState()
    func rtpsDisconnectedState()
}

final class RTPSConnectionMonitor: RTPSParticipantListenerDelegate, RTPSListenerDelegate {
    let stdParticipantList: Set<String> = ["geoserve", "trident-core", "trident-control", "trident-update", "trident-record"]
    var tridentParticipants: Set<String> = []
    var isConnected = false
    weak var delegate: RTPSConnectionMonitorProtocol? {
        didSet {
            if delegate == nil {
                tridentParticipants = []
                isConnected = false
            }
        }
    }
    
    deinit {
        FastRTPS.setRTPSParticipantListener(nil)
        FastRTPS.setRTPSListener(nil)
    }
    
    func startObserveNotifications() {
        FastRTPS.setRTPSParticipantListener(self)
    #if RTPSDEBUG
        FastRTPS.setRTPSListener(self)
    #endif
    }
    
    func readerWriterNotificaton(reason: RTPSReaderWriterNotification, topic: String, type: String, remoteLocators: String) {
    #if RTPSDEBUG
        print(reason, topic, type, remoteLocators)
    #endif
    }
    
    func RTPSNotification(reason: RTPSNotification, topic: String) {
    #if RTPSDEBUG
        print(reason, topic)
    #endif
    }
    
    func participantNotification(reason: RTPSParticipantNotification, participant: String, unicastLocators: String, properties: [String : String]) {
        switch reason {
        case .discoveredParticipant:
            if self.tridentParticipants.contains(participant) {
                print("Rediscovered Participant:", participant, unicastLocators)
                break
            }
            if self.stdParticipantList.contains(participant) {
                print("Discovered Participant:", participant, unicastLocators)
                self.tridentParticipants.insert(participant)
            } else if participant == "trident-remote-control" {
                print("Discovered Participant:", participant, unicastLocators)
                // Skip for comparability with prev. versions
                return
            } else {
                print("Unknown participant:", participant, properties, unicastLocators)
                return
            }
            if self.tridentParticipants.count == self.stdParticipantList.count {
                // All connected
                print("All needed participant discovered, start connection")
                guard !self.isConnected else { break }
                self.isConnected = true
                DispatchQueue.main.async {
                    self.delegate?.rtpsConnectedState()
                }
            }
        case .removedParticipant:
            print("Removed Participant:", participant)
        case .droppedParticipant:
            print("Dropped Participant:", participant)
            self.tridentParticipants.remove(participant)
            if self.tridentParticipants.count < self.stdParticipantList.count {
                guard self.isConnected else { break }
                print("Trident disconnected")
                self.isConnected = false
                DispatchQueue.main.async {
                    self.delegate?.rtpsDisconnectedState()
                    self.tridentParticipants = []
                }
            }
        case .changedQosParticipant:
            break
        }
    }
}
