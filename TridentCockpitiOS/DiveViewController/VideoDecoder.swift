/////
////  VideoDecoder.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

final class VideoDecoder {
    private var sampleBufferLayer: AVSampleBufferDisplayLayer
    private let NalStart = Data([0, 0, 0, 1])
    private var formatDescription: CMVideoFormatDescription?
    let timescale: Int32 = 1000000000
    var videoWiriter: VideoWriter?
    
    init(sampleBufferLayer: AVSampleBufferDisplayLayer) {
        self.sampleBufferLayer = sampleBufferLayer
    }
    
    func decodeVideo(data: Data, timestamp: UInt64) {
        let time = CMTime(value: Int64(timestamp), timescale: timescale)
        var sequenceParameterSet: [UInt8]?
        var pictureParameterSet: [UInt8]?
        var blockBuffer: CMBlockBuffer?

        var startIndex = data.startIndex
        repeat {
            let naltype = data[startIndex+4] & 0x1f

            if naltype == 1 || naltype == 5 {
                let len = data.endIndex - startIndex
                var lenBig = UInt32(len-4).bigEndian
                var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                            memoryBlock: nil,
                                                            blockLength: len,
                                                            blockAllocator: kCFAllocatorDefault,
                                                            customBlockSource: nil,
                                                            offsetToData: 0,
                                                            dataLength: len,
                                                            flags: kCMBlockBufferAssureMemoryNowFlag,
                                                            blockBufferOut: &blockBuffer)
                guard status == kCMBlockBufferNoErr else { return }
                guard let blockBuffer = blockBuffer else { return }
                status = CMBlockBufferReplaceDataBytes(with: &lenBig,
                                                       blockBuffer: blockBuffer,
                                                       offsetIntoDestination: 0,
                                                       dataLength: 4)
                guard status == kCMBlockBufferNoErr else { return }
                let naldata = data.subdata(in: startIndex+4 ..< data.endIndex)
                naldata.withUnsafeBytes { rawBufferPointer in
                    status = CMBlockBufferReplaceDataBytes(with: rawBufferPointer.baseAddress!,
                                                           blockBuffer: blockBuffer,
                                                           offsetIntoDestination: 4,
                                                           dataLength: len-4)
                }
                guard status == kCMBlockBufferNoErr else { return }
                decodeNal(blockBuffer: blockBuffer, len: len, time: time)
                
                break;
            }
            
            let endIndex: Data.Index
            if let range = data.range(of: self.NalStart, options: [], in: startIndex.advanced(by: 1) ..< data.endIndex) {
                endIndex = range.startIndex
            } else {
                endIndex = data.endIndex
            }
            
            let nal = [UInt8](data.subdata(in: startIndex+4 ..< endIndex))
            switch naltype {
            case 7:
                sequenceParameterSet = nal
            case 8:
                pictureParameterSet = nal
            default:
                break;
            }
            if let sps = sequenceParameterSet, let pps = pictureParameterSet {
                createFormatDescription(sps: sps, pps: pps)
                if let controlTimebase = sampleBufferLayer.controlTimebase {
                    CMTimebaseSetTime(controlTimebase, time: time)
                }
                videoWiriter?.startSession(at: time, format: formatDescription!)
            }

            startIndex = endIndex
        } while startIndex < data.endIndex
    }
    
    private func decodeNal(blockBuffer: CMBlockBuffer, len: Int, time: CMTime) {
        guard formatDescription != nil else { return }
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [len]
        
        var timing = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: time, decodeTimeStamp: CMTime.invalid)
        let status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault,
                                               dataBuffer: blockBuffer,
                                               formatDescription: formatDescription,
                                               sampleCount: 1,
                                               sampleTimingEntryCount: 1,
                                               sampleTimingArray: &timing,
                                               sampleSizeEntryCount: 1,
                                               sampleSizeArray: sampleSizeArray,
                                               sampleBufferOut: &sampleBuffer)
        assert(status == noErr)

        guard let buffer = sampleBuffer, CMSampleBufferGetNumSamples(buffer) > 0 else {
            return
        }
        
        videoWiriter?.addVideoData(sampleBuffer: buffer)
        
        if sampleBufferLayer.isReadyForMoreMediaData {
            sampleBufferLayer.enqueue(buffer)
        }
        if sampleBufferLayer.status == .failed {
            sampleBufferLayer.flush()
        }
    }
    
    private func createFormatDescription(sps: [UInt8], pps: [UInt8]) {
        formatDescription = nil
        let sizes = [pps.count, sps.count]
        pps.withUnsafeBufferPointer { upps in
            sps.withUnsafeBufferPointer { usps in
                let parameters = [upps.baseAddress!, usps.baseAddress!]
                let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                                                                                 parameterSetCount: 2,
                                                                                 parameterSetPointers: parameters,
                                                                                 parameterSetSizes: sizes,
                                                                                 nalUnitHeaderLength: 4,
                                                                                 formatDescriptionOut: &formatDescription)
                assert(status == noErr)
            }
        }
        
//        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription!)
//        print("Dimensions:", dimensions)
        
    }
    
    func cleanup() {
        sampleBufferLayer.flush()
        formatDescription = nil
        videoWiriter?.finishSession { self.videoWiriter = nil }
    }
    
}
