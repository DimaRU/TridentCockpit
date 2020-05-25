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

final class RTPSConnectionMonitor {
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
        NotificationCenter.default.removeObserver(self)
    }
    
    func startObserveNotifications() {
        NotificationCenter.default.addObserver(forName: .RTPSParticipantNotification, object: nil, queue: nil) { notification in
            guard let userInfo = notification.userInfo as? Dictionary<Int, Any>,
                let rawType = userInfo[RTPSNotificationUserInfo.reason.rawValue] as? Int,
                let reason = RTPSParticipantNotificationReason(rawValue: rawType)
                else { return }
            switch reason {
            case .discoveredParticipant:
                let participantName = userInfo[RTPSNotificationUserInfo.participant.rawValue] as! String
                let locators = userInfo[RTPSNotificationUserInfo.locators.rawValue] as! Set<String>
                let metaLocators = userInfo[RTPSNotificationUserInfo.metaLocators.rawValue] as! Set<String>
                let properties = userInfo[RTPSNotificationUserInfo.properties.rawValue] as! Dictionary<String, String>
                
                if self.tridentParticipants.contains(participantName) {
                    print("Rediscovered Participant:", participantName, locators)
                    break
                }
                if self.stdParticipantList.contains(participantName) {
                    print("Discovered Participant:", participantName, locators)
                    self.tridentParticipants.insert(participantName)
                } else if participantName == "trident-remote-control" {
                    print("Discovered Participant:", participantName, locators)
                    // Skip for comparability with prev. versions
                    return
                } else {
                    print("Unknown participant:", participantName, properties, locators, metaLocators)
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
                let participantName = userInfo[RTPSNotificationUserInfo.participant.rawValue] as! String
                print("Removed Participant:", participantName)
            case .droppedParticipant:
                let participantName = userInfo[RTPSNotificationUserInfo.participant.rawValue] as! String
                print("Dropped Participant:", participantName)
                self.tridentParticipants.remove(participantName)
                if self.tridentParticipants.count < self.stdParticipantList.count {
                    guard self.isConnected else { break }
                    print("Trident disconnected")
                    self.isConnected = false
                    DispatchQueue.main.async {
                        self.delegate?.rtpsDisconnectedState()
                    }
                }
        #if RTPSDEBUG
            case .discoveredReader:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                let typeName = userInfo[RTPSNotificationUserInfo.typeName.rawValue] as! String
                let locators = userInfo[RTPSNotificationUserInfo.locators.rawValue] as! Set<String>
                print("Discovered reader:", topicName, typeName, locators)
            case .discoveredWriter:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                let typeName = userInfo[RTPSNotificationUserInfo.typeName.rawValue] as! String
                let locators = userInfo[RTPSNotificationUserInfo.locators.rawValue] as! Set<String>
                print("Discovered writer:", topicName, typeName, locators)
            case .removedReader:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                print("Removed reader:", topicName)
            case .removedWriter:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                print("Removed writer:", topicName)
        #endif
            default:
                break
            }
        }
        #if RTPSDEBUG
        NotificationCenter.default.addObserver(forName: .RTPSReaderWriterNotification, object: nil, queue: nil) { notification in
            guard let userInfo = notification.userInfo as? Dictionary<Int, Any>,
                let rawType = userInfo[RTPSNotificationUserInfo.reason.rawValue] as? Int,
                let reason = RTPSReaderWriterNotificationReason(rawValue: rawType)
                else { return }
            switch reason {
            case .readerMatchedMatching:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                guard let topic = RovReaderTopic(rawValue: topicName) else { return }
                print("Matched reader:", topic)
            case .readerRemovedMatching:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                guard let topic = RovReaderTopic(rawValue: topicName) else { return }
                print("Remove matched reader:", topic)
            case .writerMatchedMatching:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                guard let topic = RovWriterTopic(rawValue: topicName) else { return }
                print("Matched writer:", topic)
            case .writerRemovedMatching:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                guard let topic = RovWriterTopic(rawValue: topicName) else { return }
                print("Remove matched writer:", topic)
            case .writerLivelinessLost:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                print("Writer Liveliness Lost:", topicName)
            case .readerLivelinessLost:
                let topicName = userInfo[RTPSNotificationUserInfo.topic.rawValue] as! String
                print("Reader Liveliness Lost:", topicName)
            default:
                break
            }
        }
        #endif
    }

}
