import AVFoundation
import CoreAudio

public protocol AudioConverterDelegate: class {
    func didSetFormatDescription(audio formatDescription: CMFormatDescription?)
    func sampleOutput(audio data: UnsafeMutableAudioBufferListPointer, presentationTimeStamp: CMTime)
}

// MARK: -
/**
 - seealse:
  - https://developer.apple.com/library/ios/technotes/tn2236/_index.html
 */
public class AudioConverter {
    enum Error: Swift.Error {
        case setPropertyError(id: AudioConverterPropertyID, status: OSStatus)
    }

    public enum Option: String, KeyPathRepresentable {
        case muted
        case bitrate
        case sampleRate
        case actualBitrate

        public var keyPath: AnyKeyPath {
            switch self {
            case .muted:
                return \AudioConverter.muted
            case .bitrate:
                return \AudioConverter.bitrate
            case .sampleRate:
                return \AudioConverter.sampleRate
            case .actualBitrate:
                return \AudioConverter.actualBitrate
            }
        }
    }

    public static let minimumBitrate: UInt32 = 8 * 1000
    public static let defaultBitrate: UInt32 = 32 * 1000
    /// 0 means according to a input source
    public static let defaultChannels: UInt32 = 0
    /// 0 means according to a input source
    public static let defaultSampleRate: Double = 0
    public static let defaultMaximumBuffers: Int = 1

    public var destination: Destination = .aac
    public weak var delegate: AudioConverterDelegate?
    public private(set) var isRunning: Atomic<Bool> = .init(false)
    public var settings: Setting<AudioConverter, Option> = [:] {
        didSet {
            settings.observer = self
        }
    }
    private static let numSamples: Int = 1024

    var muted: Bool = false
    var bitrate: UInt32 = AudioConverter.defaultBitrate {
        didSet {
            guard bitrate != oldValue else {
                return
            }
            lockQueue.async {
                if let format = self._inDestinationFormat {
                    self.setBitrateUntilNoErr(self.bitrate * format.mChannelsPerFrame)
                }
            }
        }
    }
    var sampleRate: Double = AudioConverter.defaultSampleRate
    var actualBitrate: UInt32 = AudioConverter.defaultBitrate {
        didSet {
            logger.info(actualBitrate)
        }
    }
    var channels: UInt32 = AudioConverter.defaultChannels
    var formatDescription: CMFormatDescription? {
        didSet {
            guard !CMFormatDescriptionEqual(formatDescription, otherFormatDescription: oldValue) else {
                return
            }
            logger.info(formatDescription.debugDescription)
            delegate?.didSetFormatDescription(audio: formatDescription)
        }
    }
    var lockQueue = DispatchQueue(label: "com.haishinkit.HaishinKit.AudioConverter.lock")
    var inSourceFormat: AudioStreamBasicDescription? {
        didSet {
            guard let inSourceFormat = inSourceFormat, inSourceFormat != oldValue else {
                return
            }
            _converter = nil
            formatDescription = nil
            _inDestinationFormat = nil
            logger.info("\(String(describing: inSourceFormat))")
            let nonInterleaved = inSourceFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved != 0
            maximumBuffers = nonInterleaved ? Int(inSourceFormat.mChannelsPerFrame) : AudioConverter.defaultMaximumBuffers
            currentAudioBuffer = AudioBuffer(inSourceFormat, numSamples: AudioConverter.numSamples)
        }
    }
    var effects: Set<AudioEffect> = []
    private let numSamples = AudioConverter.numSamples
    private var maximumBuffers: Int = AudioConverter.defaultMaximumBuffers
    private var currentAudioBuffer = AudioBuffer(AudioStreamBasicDescription(mSampleRate: 0, mFormatID: 0, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 0, mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0))
    private var _inDestinationFormat: AudioStreamBasicDescription?
    private var inDestinationFormat: AudioStreamBasicDescription {
        get {
            if _inDestinationFormat == nil {
                _inDestinationFormat = destination.audioStreamBasicDescription(inSourceFormat, sampleRate: sampleRate, channels: channels)
                CMAudioFormatDescriptionCreate(
                    allocator: kCFAllocatorDefault,
                    asbd: &_inDestinationFormat!,
                    layoutSize: 0,
                    layout: nil,
                    magicCookieSize: 0,
                    magicCookie: nil,
                    extensions: nil,
                    formatDescriptionOut: &formatDescription
                )
            }
            return _inDestinationFormat!
        }
        set {
            _inDestinationFormat = newValue
        }
    }

    private var audioStreamPacketDescription = AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: 0, mDataByteSize: 0) {
        didSet {
            audioStreamPacketDescriptionPointer = UnsafeMutablePointer<AudioStreamPacketDescription>(mutating: &audioStreamPacketDescription)
        }
    }
    private var audioStreamPacketDescriptionPointer: UnsafeMutablePointer<AudioStreamPacketDescription>?

    private let inputDataProc: AudioConverterComplexInputDataProc = {(
        converter: AudioConverterRef,
        ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
        ioData: UnsafeMutablePointer<AudioBufferList>,
        outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
        inUserData: UnsafeMutableRawPointer?) in
        Unmanaged<AudioConverter>.fromOpaque(inUserData!).takeUnretainedValue().onInputDataForAudioConverter(
            ioNumberDataPackets,
            ioData: ioData,
            outDataPacketDescription: outDataPacketDescription
        )
    }

    public init() {
        settings.observer = self
    }

    private var _converter: AudioConverterRef?
    private var converter: AudioConverterRef {
        var status: OSStatus = noErr
        if _converter == nil {
            var inClassDescriptions = destination.inClassDescriptions
            status = AudioConverterNewSpecific(
                &inSourceFormat!,
                &inDestinationFormat,
                UInt32(inClassDescriptions.count),
                &inClassDescriptions,
                &_converter
            )
            setBitrateUntilNoErr(bitrate * inDestinationFormat.mChannelsPerFrame)
        }
        if status != noErr {
            logger.warn("\(status)")
        }
        return _converter!
    }

    public func encodeBytes(_ bytes: UnsafeMutableRawPointer?, count: Int, presentationTimeStamp: CMTime) {
        guard isRunning.value else {
            currentAudioBuffer.clear()
            return
        }
        currentAudioBuffer.write(bytes, count: count, presentationTimeStamp: presentationTimeStamp)
        convert(numSamples * Int(destination.bytesPerFrame), presentationTimeStamp: presentationTimeStamp)
    }

    public func encodeSampleBuffer(_ sampleBuffer: CMSampleBuffer, offset: Int = 0) {
        guard let format = sampleBuffer.formatDescription, CMSampleBufferDataIsReady(sampleBuffer) && isRunning.value else {
            currentAudioBuffer.clear()
            return
        }

        inSourceFormat = format.streamBasicDescription?.pointee

        do {
            let numSamples = try currentAudioBuffer.write(sampleBuffer, offset: offset)
            if currentAudioBuffer.isReady {
                for effect in effects {
                    effect.execute(currentAudioBuffer.input, format: inSourceFormat)
                }
                if muted {
                    currentAudioBuffer.muted()
                }
                convert(currentAudioBuffer.maxLength, presentationTimeStamp: currentAudioBuffer.presentationTimeStamp)
            }
            if offset + numSamples < sampleBuffer.numSamples {
                encodeSampleBuffer(sampleBuffer, offset: offset + numSamples)
            }
        } catch {
            logger.error(error)
        }
    }

    @inline(__always)
    private func convert(_ dataBytesSize: Int, presentationTimeStamp: CMTime) {
        var finished = false
        repeat {
            var ioOutputDataPacketSize: UInt32 = destination.packetSize

            let maximumBuffers = destination.maximumBuffers((channels == 0) ? inSourceFormat?.mChannelsPerFrame ?? 1 : channels)
            let outOutputData: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: maximumBuffers)
            for i in 0..<maximumBuffers {
                outOutputData[i].mNumberChannels = inDestinationFormat.mChannelsPerFrame
                outOutputData[i].mDataByteSize = UInt32(dataBytesSize)
                outOutputData[i].mData = UnsafeMutableRawPointer.allocate(byteCount: dataBytesSize, alignment: 0)
            }

            let status = AudioConverterFillComplexBuffer(
                converter,
                inputDataProc,
                Unmanaged.passUnretained(self).toOpaque(),
                &ioOutputDataPacketSize,
                outOutputData.unsafeMutablePointer,
                nil
            )

            switch status {
            // kAudioConverterErr_InvalidInputSize: perhaps mistake. but can support macOS BuiltIn Mic #61
            case noErr, kAudioConverterErr_InvalidInputSize:
                delegate?.sampleOutput(
                    audio: outOutputData,
                    presentationTimeStamp: presentationTimeStamp
                )
            case -1:
                if destination == .pcm {
                    delegate?.sampleOutput(
                        audio: outOutputData,
                        presentationTimeStamp: presentationTimeStamp
                    )
                }
                finished = true
            default:
                finished = true
            }

            for i in 0..<outOutputData.count {
                free(outOutputData[i].mData)
            }

            free(outOutputData.unsafeMutablePointer)
        } while !finished
    }

    func invalidate() {
        lockQueue.async {
            self.inSourceFormat = nil
            self._inDestinationFormat = nil
            if let converter: AudioConverterRef = self._converter {
                AudioConverterDispose(converter)
            }
            self._converter = nil
        }
    }

    func onInputDataForAudioConverter(
        _ ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
        ioData: UnsafeMutablePointer<AudioBufferList>,
        outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?) -> OSStatus {
        guard currentAudioBuffer.isReady else {
            ioNumberDataPackets.pointee = 0
            return -1
        }

        memcpy(ioData, currentAudioBuffer.input.unsafePointer, currentAudioBuffer.listSize)
        ioNumberDataPackets.pointee = 1

        if destination == .pcm && outDataPacketDescription != nil {
            audioStreamPacketDescription.mDataByteSize = currentAudioBuffer.input.unsafePointer.pointee.mBuffers.mDataByteSize
            outDataPacketDescription?.pointee = audioStreamPacketDescriptionPointer
        }

        currentAudioBuffer.clear()

        return noErr
    }

    private func setBitrateUntilNoErr(_ bitrate: UInt32) {
        do {
            try setProperty(id: kAudioConverterEncodeBitRate, data: bitrate * inDestinationFormat.mChannelsPerFrame)
            actualBitrate = bitrate
        } catch {
            if AudioConverter.minimumBitrate < bitrate {
                setBitrateUntilNoErr(bitrate - AudioConverter.minimumBitrate)
            } else {
                actualBitrate = AudioConverter.minimumBitrate
            }
        }
    }

    private func setProperty<T>(id: AudioConverterPropertyID, data: T) throws {
        guard let converter: AudioConverterRef = _converter else {
            return
        }
        let size = UInt32(MemoryLayout<T>.size)
        var buffer = data
        let status = AudioConverterSetProperty(converter, id, size, &buffer)
        guard status == 0 else {
            throw Error.setPropertyError(id: id, status: status)
        }
    }
}

extension AudioConverter: Running {
    // MARK: Running
    public func startRunning() {
        lockQueue.async {
            self.isRunning.mutate { $0 = true }
        }
    }

    public func stopRunning() {
        lockQueue.async {
            if let convert: AudioQueueRef = self._converter {
                AudioConverterDispose(convert)
                self._converter = nil
            }
            self.currentAudioBuffer.clear()
            self.inSourceFormat = nil
            self.formatDescription = nil
            self._inDestinationFormat = nil
            self.isRunning.mutate { $0 = false }
        }
    }
}
