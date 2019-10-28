/////
////  VideoDecoder.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVFoundation
import VideoToolbox

protocol VideoDecoderDelegate: class {
    func decompressed(ciImage: CIImage, size: CGSize)
}

class VideoDecoder: NSObject {
    weak var delegate: VideoDecoderDelegate?

    private let NalStart = Data([0, 0, 0, 1])

    // instance variables
    private var formatDescription: CMVideoFormatDescription?
    private var videoSession: VTDecompressionSession?
    private var fullsps: [UInt8]?
    private var fullpps: [UInt8]?
    
    func decodeVideo(data: Data) {
        var startIndex = data.startIndex
        repeat {
            let endIndex: Data.Index
            if let range = data.range(of: self.NalStart, options: [], in: startIndex.advanced(by: 1) ..< data.endIndex) {
                endIndex = range.startIndex
            } else {
                endIndex = data.endIndex
            }
            var nal = [UInt8](data.subdata(in: startIndex ..< endIndex))
            self.processNal(&nal)
            startIndex = endIndex
        } while startIndex < data.endIndex
    }
    
    func destroyVideoSession() {
        if let session = videoSession {
            VTDecompressionSessionWaitForAsynchronousFrames(session)
            VTDecompressionSessionInvalidate(session)
            videoSession = nil
        }
        fullsps = nil
        fullpps = nil
        formatDescription = nil
    }
    

    private func processNal(_ nal: inout [UInt8]) {
        // replace the start code with the NAL size
        let len = nal.count - 4
        var lenBig = UInt32(len).bigEndian
        memcpy(&nal, &lenBig, 4)
        
        // create the video session when we have the SPS and PPS records
        let nalType = nal[4] & 0x1F
        switch nalType {
        case 7:
            fullsps = Array(nal[4...])
        case 8:
            fullpps = Array(nal[4...])
        default:
            break
        }
        
        if let sps = fullsps, let pps = fullpps {
            destroyVideoSession()
            _ = createVideoSession(sps: sps, pps: pps)
            fullsps = nil
            fullpps = nil
        }
        
        // decode the video NALs
        if videoSession != nil, nalType == 1 || nalType == 5 {
            if !decodeNal(nal) {
                print("Nel decode error")
            }
        }
    }
    
    private func decodeNal(_ nal: [UInt8]) -> Bool {
        // create the block buffer from the NAL data
        var blockBuffer: CMBlockBuffer?
        let nalPointer = UnsafeMutablePointer<UInt8>(mutating: nal)
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nalPointer, blockLength: nal.count, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: nal.count, flags: 0, blockBufferOut: &blockBuffer)
        if status != kCMBlockBufferNoErr {
            return false
        }
        
        // create the sample buffer from the block buffer
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [nal.count]
        status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer, formatDescription: formatDescription, sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 1, sampleSizeArray: sampleSizeArray, sampleBufferOut: &sampleBuffer)
        if status != noErr {
            return false
        }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, createIfNecessary: true) {
            let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(dictionary, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                 Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        
        // pass the sample buffer to the decoder
        if let buffer = sampleBuffer, CMSampleBufferGetNumSamples(buffer) > 0 {
            var infoFlags = VTDecodeInfoFlags(rawValue: 0)
            status = VTDecompressionSessionDecodeFrame(
                videoSession!,
                sampleBuffer: buffer,
                flags: [._EnableAsynchronousDecompression, ._1xRealTimePlayback],
                frameRefcon: nil,
                infoFlagsOut: &infoFlags
            )
        }
        return true
    }
    
    private func createVideoSession(sps: [UInt8], pps: [UInt8]) -> Bool {
        // create a new format description with the SPS and PPS records
        formatDescription = nil
        let parameters = [UnsafePointer<UInt8>(pps), UnsafePointer<UInt8>(sps)]
        let sizes = [pps.count, sps.count]
        var status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: UnsafePointer(parameters), parameterSetSizes: sizes, nalUnitHeaderLength: 4, formatDescriptionOut: &formatDescription)
        if status != noErr {
            return false
        }
        //        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription!)
        //        print("Dimensions:", dimensions)
        
        // create the decoder parameters
        let decoderParameters = NSMutableDictionary()
        let destinationPixelBufferAttributes = NSMutableDictionary()
        destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as String)
        
        // create the callback for getting snapshots
        var callback = VTDecompressionOutputCallbackRecord()
        callback.decompressionOutputCallback = globalDecompressionCallback
        callback.decompressionOutputRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // create the video session
        status = VTDecompressionSessionCreate(allocator: nil, formatDescription: formatDescription!, decoderSpecification: decoderParameters, imageBufferAttributes: destinationPixelBufferAttributes, outputCallback: &callback, decompressionSessionOut: &videoSession)
        return status == noErr
    }
    
    func decompressionCallback(_: UnsafeMutableRawPointer?, _: OSStatus, _: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _: CMTime, _: CMTime) {
        if let cvImageBuffer = imageBuffer {
            let ciImage = CIImage(cvImageBuffer: cvImageBuffer)
            let size = CVImageBufferGetEncodedSize(cvImageBuffer)
            self.delegate?.decompressed(ciImage: ciImage, size: size)
        }
    }
}

private func globalDecompressionCallback(_ decompressionOutputRefCon: UnsafeMutableRawPointer?, _ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime) {
    let videoDecoer: VideoDecoder = unsafeBitCast(decompressionOutputRefCon, to: VideoDecoder.self)
    videoDecoer.decompressionCallback(sourceFrameRefCon, status, infoFlags, imageBuffer, presentationTimeStamp, presentationDuration)
}
