/////
////  AuxCameraControlView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import PromiseKit

class AuxCameraControlView: NSView, FloatingViewProtocol {
    var xConstraint: NSLayoutConstraint?
    var yConstraint: NSLayoutConstraint?

    var mousePosRelatedToView: CGPoint?
    var isDragging: Bool = false
    var cpv: CGFloat = 0
    var cph: CGFloat = 0
    let alignConst: CGFloat = 0
    var isAlignFeedbackSent = false
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var recordingButton: FlatButton!
    @IBOutlet weak var powerButton: NSButton!
    @IBOutlet weak var recordingTimeLabel: NSTextField!
    @IBOutlet weak var cameraTimeLabel: NSTextField!
    @IBOutlet weak var batteryStatusLabel: NSTextField!
    @IBOutlet weak var liveVideoButton: NSButton!
    private var liveViewWindowController: NSWindowController?
    
    var timer: Timer?
    private enum CameraControlViewState {
        case off
        case on
        case recording
    }
    
    private var cameraState: CameraControlViewState = .on {
        didSet {
            if oldValue != cameraState {
                setup(state: cameraState)
            }
        }
    }
    
    private var cameraTime: UInt32 = 0 {
        didSet {
            guard cameraTime != 65535 else { return }
            var time = "Remaining time:\n"
            if cameraTime / 60 != 0 {
                time += String(cameraTime / 60) + "h "
            }
            if cameraTime % 60 != 0 {
                time += String(cameraTime % 60) + "m"
            }
            self.cameraTimeLabel.stringValue = time
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.roundCorners(withRadius: 6)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer?.backgroundColor = NSColor(named: "cameraControlBackground")!.cgColor
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownAct(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        mouseDraggedAct(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        mouseUpAct(with: event)
    }

    func savePosition(cph: CGFloat, cpv: CGFloat) {
        Preference.auxCameraControlViewCPH = cph
        Preference.auxCameraControlViewCPV = cpv
    }
    
    func loadPosition() -> (cph: CGFloat?, cpv: CGFloat?) {
        return (
            Preference.auxCameraControlViewCPH,
            Preference.auxCameraControlViewCPV
        )
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        guard newWindow == nil else { return }
        timer?.invalidate()
        timer = nil
        liveViewWindowController?.close()
        liveViewWindowController = nil
    }
    
    #if DEBUG
    deinit {
        print(className, #function)
    }
    #endif
    
    // MARK: Instaniate
    static func instantiate(superView: NSView) -> AuxCameraControlView {
        let view = AuxCameraControlView()
        let nib = NSNib(nibNamed: .init("AuxCameraControlView"), bundle: nil)!
        nib.instantiate(withOwner: view, topLevelObjects: nil)
        view.addSubview(view.contentView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: view.contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor)
        ])
        superView.addSubview(view)
        let defX = superView.frame.minX + view.contentView.frame.midX
        let defY = superView.frame.minY + view.contentView.frame.midY
        view.addConstraints(defX: defX, defY: defY)
        
        view.recordingTimeLabel.stringValue = ""
        view.batteryStatusLabel.stringValue = "n/a"
        view.cameraTimeLabel.stringValue = ""

        view.setup(state: .on)
        view.setRefreshTimer(timeInterval: 2)
        return view
    }
    
    
    private func setup(state: CameraControlViewState) {
        switch state {
        case .off:
            liveViewWindowController?.close()
            liveViewWindowController = nil
            powerButton.state = .off
            liveVideoButton.isHidden = true
            recordingTimeLabel.stringValue = ""
            batteryStatusLabel.stringValue = "n/a"
            cameraTimeLabel.stringValue = ""
            cameraTimeLabel.textColor = .systemGray
            recordingButton.activeButtonColor = NSColor(named: "stopActive")!
            recordingButton.buttonColor = NSColor(named: "stopNActive")!
        case .on:
            powerButton.state = .on
            powerButton.isHidden = false
            liveVideoButton.isHidden = false
            recordingTimeLabel.stringValue = ""
            cameraTimeLabel.textColor = .systemGray
            recordingButton.activeButtonColor = NSColor(named: "stopActive")!
            recordingButton.buttonColor = NSColor(named: "stopNActive")!
        case .recording:
            powerButton.isHidden = true
            recordingButton.activeButtonColor = NSColor(named: "recordActive")!
            recordingButton.buttonColor = NSColor(named: "recordNActive")!
            cameraTimeLabel.textColor = .white
        }
    }
    
    private func refreshCameraStatus() {
        Gopro3API.requestData(.status)
        .done {
            self.decodeCameraStatus(data: $0)
        }.catch { error in
            switch error {
            case NetworkError.gone:
                // camera is off
                self.cameraState = .off
                self.timer?.invalidate()
                self.timer = nil
            case NetworkError.unaviable(let message):
                self.window?.alert(message: "Payload camera connection lost", informative: message, delay: 3)
                self.timer?.invalidate()
                self.timer = nil
            default:
                self.window?.alert(error: error)
            }
        }
    }
    
    private func decodeCameraStatus(data: Data) {
        let status = GoproStatus(data: data)
        cameraState = status.recording ? .recording : .on
        batteryStatusLabel.stringValue = status.battery
        cameraTime = status.videoRemaining
        if status.recording {
            let (hour, min, sec) = status.videoProgress
            recordingTimeLabel.stringValue = String(format: "%2.2d:%2.2d:%2.2d", hour, min, sec)
        }
    }
    
    @objc private func windowWillClose(notification: Notification) {
        guard let object = notification.object as? NSWindow else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: object)
        liveViewWindowController = nil
        liveVideoButton.isEnabled = true
    }
    
    private func setRefreshTimer(timeInterval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] in
            self?.refreshCameraStatus()
            if $0.timeInterval == 2 {
                self?.setRefreshTimer(timeInterval: 10)
            }
        }
    }
    
    @IBAction func powerButtonPress(_ sender: Any) {
        let powerOn: Bool
        switch cameraState {
        case .off       : powerOn = true
        case .on        : powerOn = false
        case .recording : return
        }
        
        Gopro3API.request(.power(on: powerOn))
        .then { (Void) -> Promise<Data> in
            if powerOn {
                return Gopro3API.attempt(retryCount: 10, delay: .seconds(1)) {
                    Gopro3API.requestData(.status)
                }
            } else {
                return Promise<Data>.value(Data())
            }
        }.done { _ in
            if powerOn {
                self.setRefreshTimer(timeInterval: 2)
            } else {
                self.timer?.invalidate()
                self.timer = nil
            }
            self.cameraState = powerOn ? .on : .off
        }.catch {
            self.window?.alert(error: $0)
        }
    }
    
    @IBAction func recordingButtonPress(_ sender: Any) {
        let shotOn: Bool
        switch cameraState {
        case .off       : return
        case .on        : shotOn = true
        case .recording : shotOn = false
        }
        Gopro3API.attempt(retryCount: 5, delay: .milliseconds(500)) {
            Gopro3API.request(.shot(on: shotOn))
        }.done {
            self.cameraState = shotOn ? .recording : .on
            self.setRefreshTimer(timeInterval: shotOn ? 1 : 2)
        }.catch {
            self.window?.alert(error: $0)
        }
    }
    
    @IBAction func liveVideoButtonPress(_ sender: Any) {
        guard liveViewWindowController == nil else { return }
        let storyboard = NSStoryboard(name: .init("AuxPlayerViewController"), bundle: nil)
        guard let windowControler = storyboard.instantiateInitialController() as? NSWindowController else { return }
        let panel = windowControler.window! as! NSPanel
        panel.isFloatingPanel = true
        windowControler.window!.contentAspectRatio = NSSize(width: 16, height: 9)
        if let auxPlayerViewController = windowControler.contentViewController as? AuxPlayerViewController {
            auxPlayerViewController.videoURL = Gopro3API.liveStreamURL
        }
        windowControler.showWindow(nil)
        liveViewWindowController = windowControler
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(notification:)), name: NSWindow.willCloseNotification, object: windowControler.window)
        liveVideoButton.isEnabled = false
    }
}
