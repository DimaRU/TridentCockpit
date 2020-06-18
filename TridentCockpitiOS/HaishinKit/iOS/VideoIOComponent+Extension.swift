#if os(iOS)

import AVFoundation
import CoreImage

extension VideoIOComponent {
    var zoomFactor: CGFloat {
        guard let device: AVCaptureDevice = (input as? AVCaptureDeviceInput)?.device else {
            return 0
        }
        return device.videoZoomFactor
    }

    func setZoomFactor(_ zoomFactor: CGFloat, ramping: Bool, withRate: Float) {
        guard let device: AVCaptureDevice = (input as? AVCaptureDeviceInput)?.device,
            1 <= zoomFactor && zoomFactor < device.activeFormat.videoMaxZoomFactor
            else { return }
        do {
            try device.lockForConfiguration()
            if ramping {
                device.ramp(toVideoZoomFactor: zoomFactor, withRate: withRate)
            } else {
                device.videoZoomFactor = zoomFactor
            }
            device.unlockForConfiguration()
        } catch let error as NSError {
            logger.error("while locking device for ramp: \(error)")
        }
    }

    func attachScreen(_ screen: CustomCaptureSession?, useScreenSize: Bool = true) {
        guard let screen: CustomCaptureSession = screen else {
            self.screen?.stopRunning()
            self.screen = nil
            return
        }
        input = nil
        output = nil
        if useScreenSize {
            encoder.width = screen.attributes["Width"] as! Int32
            encoder.height = screen.attributes["Height"] as! Int32
        }
        self.screen = screen
    }
}

extension VideoIOComponent: ScreenCaptureOutputPixelBufferDelegate {
    // MARK: ScreenCaptureOutputPixelBufferDelegate
    func didSet(size: CGSize) {
        lockQueue.async {
            self.encoder.width = Int32(size.width)
            self.encoder.height = Int32(size.height)
        }
    }

    func output(pixelBuffer: CVPixelBuffer, withPresentationTime: CMTime) {
        if !effects.isEmpty {
            // usually the context comes from HKView or MTLHKView
            // but if you have not attached a view then the context is nil
            if context == nil {
                logger.info("no ci context, creating one to render effect")
                context = CIContext()
            }
            context?.render(effect(pixelBuffer, info: nil), to: pixelBuffer)
        }
        encoder.encodeImageBuffer(
            pixelBuffer,
            presentationTimeStamp: withPresentationTime,
            duration: CMTime.invalid
        )
    }
}

#endif
