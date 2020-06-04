/////
////  GetWifiAPTableViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

protocol GetWifiAPProtocol: NSObject {
    func wifiAP(ssid: String, password: String)
}
class GetWifiAPTableViewController: UITableViewController {

    @IBOutlet weak var ssidTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    weak var delegate: GetWifiAPProtocol?

    required init?(coder: NSCoder, delegate: GetWifiAPProtocol) {
        self.delegate = delegate
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ssidTextField.text = Preference.ssidName ?? ""
        passwordTextField.text = Preference.ssidPassword ?? ""
        
        if !ssidTextField.text!.isEmpty, !passwordTextField.text!.isEmpty {
            doneButton.isEnabled = true
        }
        ssidTextField.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            self.doneButton.isEnabled = !self.ssidTextField.text!.isEmpty && !self.passwordTextField.text!.isEmpty
        }
     }

    @IBAction func doneButtonPress(_ sender: Any) {
        guard ssidTextField.text != "", passwordTextField.text != "" else { return }
        dismiss(animated: true) {
            Preference.ssidName = self.ssidTextField.text!
            Preference.ssidPassword = self.passwordTextField.text!
            self.delegate?.wifiAP(ssid: self.ssidTextField.text!, password: self.passwordTextField.text!)
        }
    }
    
    @IBAction func cancelButtonPress(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

extension GetWifiAPTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case ssidTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            doneButtonPress(textField)
        default:
            return false
        }
        return true
    }
}
