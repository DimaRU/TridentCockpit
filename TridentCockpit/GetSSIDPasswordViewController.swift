/////
////  GetSSIDPasswordViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

protocol GetSSIDPasswordProtocol: NSObject {
    func enteredPassword(ssid: String, password: String)
}

class GetSSIDPasswordViewController: NSViewController {
    @IBOutlet weak var ssidTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    
    weak var delegate: GetSSIDPasswordProtocol?
    var ssid: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ssidTextField.stringValue = NSLocalizedString("Password for Wi-Fi network ", comment: "") + "\"" + ssid + "\""
        if let password = KeychainService.get(key: ssid) {
            passwordTextField.stringValue = password
        }
    }
    
    @IBAction func cancelButtonPress(_ sender: Any) {
        dismiss(sender)
    }
    
    @IBAction func okButtonPress(_ sender: Any) {
        delegate?.enteredPassword(ssid: ssid, password: passwordTextField.stringValue)
        dismiss(sender)
    }
}
