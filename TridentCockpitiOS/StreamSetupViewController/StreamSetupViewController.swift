/////
////  StreamSetupViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

protocol StreamSetupViewControllerDelegate: class {
    func streamer(_ videoStreamer: VideoStreamer?)
}

class StreamSetupViewController: UIViewController {
    @IBOutlet weak var serverURLField: UITextField!
    @IBOutlet weak var streamKeyField: UITextField!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var connectButton: UIButton!
    private var videoStreamer: VideoStreamer?
    weak var delegate: StreamSetupViewControllerDelegate?

    required init?(coder: NSCoder, delegate: StreamSetupViewControllerDelegate) {
        self.delegate = delegate
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        serverURLField.text = Preference.streamURL ?? ""
        streamKeyField.text = Preference.streamKey ?? ""
        serverURLField.becomeFirstResponder()
    }
    
    @IBAction func connectButtonPress(_ sender: Any) {
        serverURLField.resignFirstResponder()
        streamKeyField.resignFirstResponder()
        if connectButton.isSelected {
            videoStreamer?.disconnect()
            videoStreamer = nil
            delegate?.streamer(nil)
            connectButton.isSelected = false
            cancelButton.title = "Cancel"
            return
        }
        guard checkInput() else { return }
        
        Preference.streamURL = serverURLField.text!
        Preference.streamKey = streamKeyField.text!
        videoStreamer = VideoStreamer(url: serverURLField.text!, key: streamKeyField.text!)
        videoStreamer?.setVideoFormat()
        videoStreamer?.delegate = self
        videoStreamer?.connect()
    }
    
    @IBAction func cancelButtonPress(_ sender: Any) {
        dismiss(animated: true) {
            self.videoStreamer?.delegate = nil
        }
    }

    private func checkInput() -> Bool {
        guard
            let serverURL = serverURLField.text,
            let streamKey = streamKeyField.text,
            let url = URL(string: serverURL),
            let scheme = url.scheme,
            !streamKey.isEmpty else {
                return false
        }
        return RTMPConnection.supportedProtocols.contains(scheme)
    }
}

extension StreamSetupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case serverURLField:
            streamKeyField.becomeFirstResponder()
        case streamKeyField:
            connectButtonPress(textField)
        default:
            return false
        }
        return true
    }
}

extension StreamSetupViewController: VideoStreamerDelegate {
    func showError(_ error: StreamerError) {
        error.alert(delay: 5)
    }
    
    func stats(fps: UInt16, bytesOutPerSecond: Int32, totalBytesOut: Int64) {}
    
    func state(published: Bool) {
        guard published else { return }
        DispatchQueue.main.async {
            self.connectButton.isSelected = true
            self.cancelButton.title = "Done"
            self.delegate?.streamer(self.videoStreamer!)
        }
    }
}
