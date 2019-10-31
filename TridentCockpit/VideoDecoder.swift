/////
////  VideoDecoder.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVFoundation
import VideoToolbox

final class VideoDecoder: NSObject {
    private var sampleBufferLayer: AVSampleBufferDisplayLayer
    private let NalStart = Data([0, 0, 0, 1])

    // instance variables
    private var formatDescription: CMVideoFormatDescription?
    private var fullsps: [UInt8]?
    private var fullpps: [UInt8]?
    let timescale: Int32 = 1000000000
    
    init(sampleBufferLayer: AVSampleBufferDisplayLayer) {
        self.sampleBufferLayer = sampleBufferLayer
        super.init()
    }
    
    func decodeVideo(data: Data, timestamp: UInt64) {
        let time = CMTime(value: Int64(timestamp), timescale: timescale)
        
        var startIndex = data.startIndex
        repeat {
            let naltype = data[startIndex+4] & 0x1f
            if naltype == 1 || naltype == 5 {
                var nal = [UInt8](data.subdata(in: startIndex ..< data.endIndex))
                decodeNal(&nal, time: time)
                break;
            }
            let endIndex: Data.Index
            if let range = data.range(of: self.NalStart, options: [], in: startIndex.advanced(by: 1) ..< data.endIndex) {
                endIndex = range.startIndex
            } else {
                endIndex = data.endIndex
            }
            let nal = [UInt8](data.subdata(in: startIndex ..< endIndex))
            self.processNal(nal, time: time)
            startIndex = endIndex
        } while startIndex < data.endIndex
    }
    
    private func processNal(_ nal: [UInt8], time: CMTime) {
        
        let nalType = nal[4] & 0x1F
        switch nalType {
        case 7:
            fullsps = Array(nal[4...])
        case 8:
            fullpps = Array(nal[4...])
        default:
            break;
        }
        
        if let sps = fullsps, let pps = fullpps {
            createFormatDescription(sps: sps, pps: pps)
            fullsps = nil
            fullpps = nil
        }
        
    }
    
    private func decodeNal(_ nal: inout [UInt8], time: CMTime) {
        guard formatDescription != nil else { return }
        // replace the start code with the NAL size
        let len = nal.count - 4
        var lenBig = UInt32(len).bigEndian
        memcpy(&nal, &lenBig, 4)

        var blockBuffer: CMBlockBuffer?
        let nalPointer = UnsafeMutablePointer<UInt8>(mutating: nal)
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                        memoryBlock: nalPointer,
                                                        blockLength: nal.count,
                                                        blockAllocator: kCFAllocatorNull,
                                                        customBlockSource: nil,
                                                        offsetToData: 0,
                                                        dataLength: nal.count,
                                                        flags: 0,
                                                        blockBufferOut: &blockBuffer)
        if status != kCMBlockBufferNoErr {
            print("Nal decode error CMBlockBufferCreateWithMemoryBlock")
        }
        
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [nal.count]

        status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault,
                                           dataBuffer: blockBuffer,
                                           formatDescription: formatDescription,
                                           sampleCount: 1,
                                           sampleTimingEntryCount: 0,
                                           sampleTimingArray: nil,
                                           sampleSizeEntryCount: 1,
                                           sampleSizeArray: sampleSizeArray,
                                           sampleBufferOut: &sampleBuffer)
        if status != noErr {
            print("Nal decode error CMSampleBufferCreateReady")
        }
        
        guard let buffer = sampleBuffer, CMSampleBufferGetNumSamples(buffer) > 0 else {
            return
        }
        
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true) {
            let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(dictionary,
                                 Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                 Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        
        if sampleBufferLayer.isReadyForMoreMediaData {
            sampleBufferLayer.enqueue(buffer)
        } else {
            print("!isReadyForMoreMediaData")
        }
        if sampleBufferLayer.status == .failed {
            sampleBufferLayer.flush()
            print("sampleBufferLayer.status == .failed")
        }

    }
    
    private func createFormatDescription(sps: [UInt8], pps: [UInt8]) {
        // create a new format description with the SPS and PPS records
        formatDescription = nil
        let parameters = [UnsafePointer<UInt8>(pps), UnsafePointer<UInt8>(sps)]
        let sizes = [pps.count, sps.count]
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                                                                         parameterSetCount: 2,
                                                                         parameterSetPointers: UnsafePointer(parameters),
                                                                         parameterSetSizes: sizes,
                                                                         nalUnitHeaderLength: 4,
                                                                         formatDescriptionOut: &formatDescription)
        
        if status != noErr {
            print("Error create formatDescription")
        }
//        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription!)
//        print("Dimensions:", dimensions)
    }
    
    func destroyVideoSession() {
        sampleBufferLayer.flush()
        fullsps = nil
        fullpps = nil
        formatDescription = nil
    }
    
}
