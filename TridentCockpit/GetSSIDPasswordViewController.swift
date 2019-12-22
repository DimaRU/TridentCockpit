/////
////  GetSSIDPasswordViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Cocoa

protocol GetPasswordProtocol: NSObject {
    func enteredPassword(ssid: String, password: String)
}

class GetSSIDPasswordViewController: NSViewController {
    @IBOutlet weak var ssidTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    
    weak var delegate: GetPasswordProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cancelButtonPress(_ sender: Any) {
        dismiss(sender)
    }
    
    @IBAction func okButtonPress(_ sender: Any) {
        delegate?.enteredPassword(ssid: ssidTextField.stringValue, password: passwordTextField.stringValue)
        dismiss(sender)
    }
}
