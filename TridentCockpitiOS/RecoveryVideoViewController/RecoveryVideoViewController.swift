/////
////  RecoveryVideoViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import Shout
import UICircularProgressRing

class RecoveryVideoViewController: UIViewController {
    @IBOutlet weak var progressView: UICircularProgressRing!
    @IBOutlet weak var recoveryButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var fileCountLabel: UILabel!
    @IBOutlet weak var totalSizeLabel: UILabel!
    @IBOutlet weak var freeSpaceLabel: UILabel!
    @IBOutlet weak var infoStackView: UIStackView!
    
    private var ssh: SSH?
    var fileProgress = ""
    var progressType = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.valueFormatter = self
        progressView.delegate = self
        recoveryButton.isHidden = true
        dismissButton.isHidden = true
        infoStackView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkInstallUntrunc()
    }
    
    @IBAction func dismissButtonPress(_ sender: Any) {
        ssh = nil
        let pastDivesViewController = (presentingViewController as? UINavigationController)?.topViewController as? PastDivesViewController
        self.dismiss(animated: true) {
            pastDivesViewController?.refreshRecordings()
        }
    }

    @IBAction func recoveryButtonPress(_ sender: Any) {
        progressView.resetProgress()
        UIView.animate(withDuration: 0.1, animations: {
            self.progressView.isHidden = false
            self.infoStackView.isHidden = true
            self.recoveryButton.isHidden = true
        }) { _ in
            self.recoveryVideo()
        }
    }

    private func showError(_ error: Error)
    {
        DispatchQueue.main.async {
            // Show error
            UIApplication.shared.isIdleTimerDisabled = false
            error.alert(delay: 60)
            self.recoveryButton.isHidden = true
            self.dismissButton.isHidden = false
        }
        
    }
    
    private func checkInstallUntrunc() {
        let login = GlobalParams.rovLogin
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        

        UIApplication.shared.isIdleTimerDisabled = true
        let spinner = SwiftSpinner.addCircularProgress(to: self.view,
                                                   title: "Setup recovery",
                                                   verticalSizeClass: self.traitCollection.verticalSizeClass)
        let removeSpinner = {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
                spinner.hide() {
                    spinner.removeConstraints(spinner.constraints)
                    spinner.removeFromSuperview()
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.ssh = try SSH(host: FastRTPS.remoteAddress, numericHost: true)
                guard let ssh = self.ssh else { return }
                
                try ssh.authenticate(username: login, password: password)
                let sftp = try ssh.openSftp()
                if let checkFileList = try? sftp.listFiles(in: "/opt/openrov/untrunc"),
                    checkFileList.keys.contains("donor.mp4"),
                    checkFileList.keys.contains("untrunc") {} else {
                    let zipFileURL = Bundle.main.url(forResource: "untrunc", withExtension: "zip")!
                    try sftp.upload(localURL: zipFileURL, remotePath: "untrunc.zip")
                    let script = """
                    set -e
                    echo \(password) | sudo -S echo START-SCRIPT
                    sudo unzip -u untrunc.zip -d /opt/openrov/untrunc 2>&1
                    rm -rf untrunc.zip 2>&1
                    """
                    let (status, log) = try ssh.capture(script)
                     if status != 0 {
                        removeSpinner()
                        let error = SSH.ScriptError.scriptError(name: "unzip", log: log)
                        self.showError(error)
                        return
                    }
                }
                let script1 = "/opt/openrov/untrunc/untrunc list /data/openrov/video/sessions 2>&1"
                let (status, log) = try ssh.capture(script1)
                removeSpinner()
                if status != 0 {
                    let error = SSH.ScriptError.scriptError(name: "list", log: log)
                    self.showError(error)
                    return
                }
                DispatchQueue.main.async {
                    self.showInfo(log)
                }

            } catch {
                removeSpinner()
                self.showError(error)
            }
        }
    }
    
    private func showInfo(_ log: String) {
        let formater = ByteCountFormatter()
        formater.countStyle = .file
        let info = log.split(separator: "\n").map { $0.split(separator: ":") }
        let fileSizes = info.compactMap{ $0.first == "File" ? Int64($0.last!):nil }
        guard
            let totals = info.first(where: { $0[0] == "Files/free" })?.last?.split(separator: "/"),
            let fileCount = Int(totals[0]),
            let freeSpace = Int64(totals[1]),
            fileCount == fileSizes.count
        else {
            // Wrong reply
            let error = SSH.ScriptError.scriptError(name: "list internal error", log: log)
            self.showError(error)
            return
        }

        let maxFileSize = fileSizes.max() ?? 0
        let totalFileSize = fileSizes.reduce(0, +)
        
        // Show data
        fileCountLabel.text = "Videos for recovery: \(fileCount)"
        freeSpaceLabel.text = "Free space: " + formater.string(fromByteCount: freeSpace)
        totalSizeLabel.text = "Total size: " + formater.string(fromByteCount: totalFileSize)
        infoStackView.isHidden = false

        guard fileCount != 0 else {
            // No files for recovery
            dismissButton.isHidden = false
            return
        }
        
        guard freeSpace > maxFileSize else {
            // No free space
            let needed = formater.string(fromByteCount: maxFileSize)
            let error = SSH.ScriptError.scriptError(name: "No free space. Needed \(needed)", log: "")
            self.showError(error)
            return
        }

        recoveryButton.isHidden = false
    }

    
    private func recoveryVideo() {
        UIApplication.shared.isIdleTimerDisabled = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let ssh = self.ssh else { return }
                let script = "/opt/openrov/untrunc/untrunc recovery /opt/openrov/untrunc/donor.mp4 /data/openrov/video/sessions"
                let status = try ssh.execute(script) { log in
                    DispatchQueue.main.async {
                        self.showProgress(log)
                    }
                }
                print("End:", status)
                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = false
                    self.progressView.startProgress(to: 100, duration: 0.1)
                    self.dismissButton.isHidden = false
                }
            } catch {
                self.showError(error)
            }
        }
    }
    
    private func showProgress(_ log: String) {
        let logStrings = log.trimmingCharacters(in: .newlines).split(separator: ":")
        guard logStrings.count == 2 else { return }
        switch logStrings[0] {
        case "Count":
            fileProgress = String(logStrings[1])
            progressView.resetProgress()
        case "Save":
            progressType = "Recovery:"
            let value = logStrings[1].trimmingCharacters(in: .init(charactersIn: "%"))
            progressView.startProgress(to: CGFloat(Int(value) ?? 0), duration: 0.1)
        case "Check":
            progressType = "Check:"
            let value = logStrings[1].trimmingCharacters(in: .init(charactersIn: "%"))
            progressView.startProgress(to: CGFloat(Int(value) ?? 0), duration: 0.1)
        default:
            return
        }
    }
}

extension RecoveryVideoViewController: UICircularRingValueFormatter, UICircularProgressRingDelegate {
    func didFinishProgress(for ring: UICircularProgressRing) {}
    func didPauseProgress(for ring: UICircularProgressRing) {}
    func didContinueProgress(for ring: UICircularProgressRing) {}
    func didUpdateProgressValue(for ring: UICircularProgressRing, to newValue: CGFloat) {}

    func willDisplayLabel(for ring: UICircularProgressRing, _ label: UILabel) {
        label.numberOfLines = 2
    }
    
    func string(for value: Any) -> String? {
        guard let value = value as? CGFloat else { return nil }
        if fileProgress == "" {
            return "\(progressType) \(Int(value))%"
        } else {
            return "Video \(fileProgress)\n\(progressType) \(Int(value))%"
        }
    }
    
}
