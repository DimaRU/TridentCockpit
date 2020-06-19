/////
////  StreamSetupViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

protocol StreamSetupViewControllerDelegate: class {
    func streamer(_ videoStreamer: VideoStreamer)
}

class StreamSetupViewController: UIViewController {
    @IBOutlet weak var serverURLField: UITextField!
    @IBOutlet weak var streamKeyField: UITextField!
    @IBOutlet weak var connectButton: UIBarButtonItem!
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
        guard checkInput() else { return }
        
        Preference.streamURL = serverURLField.text!
        Preference.streamKey = streamKeyField.text!
        videoStreamer = VideoStreamer(url: serverURLField.text!, name: streamKeyField.text!)
        videoStreamer?.delegate = self
        videoStreamer?.connect()
    }
    
    @IBAction func cancelButtonPress(_ sender: Any) {
        dismiss(animated: true)
    }

    private func checkInput() -> Bool {
        guard
            let serverURL = serverURLField.text,
            let streamKey = streamKeyField.text,
            let url = URL(string: serverURL),
            !streamKey.isEmpty else {
                return false
        }
        if url.scheme == "rtmp" || url.scheme == "rtmps" {
            return true
        }
        return false
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
    func state(connected: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.connectButton.title = "Connected"
            }) { finished in
                self.dismiss(animated: true) {
                    self.delegate?.streamer(self.videoStreamer!)
                }
            }
        }
    }
}
