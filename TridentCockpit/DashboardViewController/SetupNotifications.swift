/////
////  SetupNotifications.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import FastRTPSBridge

extension DashboardViewController {
    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .RTPSParticipantNotification, object: nil, queue: nil) { notification in
            guard let userInfo = notification.userInfo as? Dictionary<Int, Any>,
                let rawType = userInfo[RTPSNotificationUserInfo.reason.rawValue] as? Int,
                let reason = RTPSParticipantNotificationReason(rawValue: rawType)
                else { return }
            switch reason {
            case .discoveredParticipant:
                let participantName = userInfo[RTPSNotificationUserInfo.participant.rawValue] as! String
                let properties = userInfo[RTPSNotificationUserInfo.properties.rawValue] as! Dictionary<String, String>
                let locators = userInfo[RTPSNotificationUserInfo.locators.rawValue] as! Set<String>
                let metaLocators = userInfo[RTPSNotificationUserInfo.metaLocators.rawValue] as! Set<String>
                print("Discovered Participant:", participantName, properties, locators, metaLocators)
                if self.stdParticipantList.contains(participantName) {
                    self.tridentParticipants.insert(participantName)
                } else {
                    print("Unknown participant:", participantName)
                }
                if self.tridentParticipants.count == self.stdParticipantList.count {
                    // All connected
                    DispatchQueue.main.async {
                        self.setConnectedState()
                    }
                }
            case .removedParticipant:
                let participantName = userInfo[RTPSNotificationUserInfo.participant.rawValue] as! String
                print("Removed Participant:", participantName)
            case .droppedParticipant:
                let participantName = userInfo[RTPSNotificationUserInfo.participant.rawValue] as! String
                print("Dropped Participant:", participantName)
                self.tridentParticipants.remove(participantName)
                if self.tridentParticipants.count == self.stdParticipantList.count - 1 {
                    DispatchQueue.main.async {
                        self.setDisconnectedState()
                    }
                }
                #if DEBUG
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
            default:
                break
            }
        }
    }
}
