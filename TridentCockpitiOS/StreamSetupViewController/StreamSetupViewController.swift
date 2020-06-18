/////
////  StreamSetupViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

class StreamSetupViewController: UIViewController {
    @IBOutlet weak var serverURLField: UITextField!
    @IBOutlet weak var streamKeyField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    
    private var videoStreamer: VideoStreamer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        serverURLField.becomeFirstResponder()
    }
    
    @IBAction func connectButtonPress(_ sender: Any) {
        guard checkInput(), !connectButton.isSelected else { return }
        
        
        videoStreamer = VideoStreamer(url: serverURLField.text!, name: streamKeyField.text!)
        videoStreamer?.delegate = self
        videoStreamer?.connect()
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
        connectButton.isSelected = connected
    }
}
