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
    @IBOutlet weak var logButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private enum RecoveryResult: String { case Wait, Fail, Recovered, Deleted, Visible
        var color: UIColor {
            switch self {
            case .Wait: return .black
            case .Fail: return .systemRed
            case .Recovered: return .systemGreen
            case .Deleted: return .systemGray
            case .Visible: return .black
            }
        }
    }
    
    private let VersionString = "Version:2"
    private var ssh: SSH?
    private var fileProgress = ""
    private var progressType = ""
    private var errorLog = ""
    private var entryList: [String] = []
    private var result: [RecoveryResult] = []
    private var fileSize: [Int64] = []
    private let formater = ByteCountFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        formater.countStyle = .file
        progressView.valueFormatter = self
        progressView.delegate = self
        recoveryButton.isHidden = true
        dismissButton.isHidden = true
        infoStackView.isHidden = true
        tableView.isHidden = true
        presentationController?.delegate = self
        checkInstallUntrunc()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

    @IBSegueAction private func showRecoveryLog(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> RecoveryLogViewController? {
        let recoveryLogViewController = RecoveryLogViewController(coder: coder)
        recoveryLogViewController?.errorLog = errorLog
        return recoveryLogViewController
    }
    
    private func showError(_ error: Error)
    {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            error.alert(delay: 300)
            self.recoveryButton.isHidden = true
            self.dismissButton.isHidden = false
        }
    }
    
    private func checkInstallUntrunc() {
        let login = GlobalParams.rovLogin
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        var version: String?
        var info = ""

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
                
                while version != self.VersionString {
                    if version == nil,
                       let checkFileList = try? sftp.listFiles(in: "/opt/openrov/untrunc"),
                       checkFileList.keys.contains("donor.mp4"),
                       checkFileList.keys.contains("untrunc") {} else {
                        let zipFileURL = Bundle.main.url(forResource: "untrunc", withExtension: "zip")!
                        try sftp.upload(localURL: zipFileURL, remotePath: "untrunc.zip")
                        let script = """
                        set -e
                        echo \(password) | sudo -S echo START-SCRIPT
                        sudo unzip -o untrunc.zip -d /opt/openrov/untrunc 2>&1
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
                    if status != 0 {
                        removeSpinner()
                        let error = SSH.ScriptError.scriptError(name: "list", log: log)
                        self.showError(error)
                        return
                    }
                    info = log
                    version = String(log.split(separator: "\n").first(where: { $0 == self.VersionString }) ?? "")
                }
                removeSpinner()
                DispatchQueue.main.async {
                    self.showInfo(info)
                }
            } catch {
                removeSpinner()
                self.showError(error)
            }
        }
    }
    
    private func showInfo(_ log: String) {
        let info = log.split(separator: "\n").map { $0.split(separator: ":") }
        entryList = info.filter{ $0.first == "Entry"}.map { String($0[1]) }
        result = Array.init(repeating: .Wait, count: entryList.count)
        fileSize = info.compactMap{ $0.first == "Entry" ? Int64($0.last!):nil }
        guard
            let totals = info.first(where: { $0[0] == "Files/free" })?.last?.split(separator: "/"),
            let fileCount = Int(totals[0]),
            let freeSpace = Int64(totals[1]),
            fileCount == fileSize.count
        else {
            // Wrong reply
            let error = SSH.ScriptError.scriptError(name: "list command", log: log)
            self.showError(error)
            return
        }

        let maxFileSize = fileSize.max() ?? 0
        let totalFileSize = fileSize.reduce(0, +)
        
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
        var logs = ""
        UIApplication.shared.isIdleTimerDisabled = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let ssh = self.ssh else { return }
                for index in self.entryList.indices {
                    logs = ""
                    self.fileProgress = "\(index+1)/\(self.entryList.count)"
                    let script = "/opt/openrov/untrunc/untrunc recovery /opt/openrov/untrunc/donor.mp4 \(self.entryList[index]) 2>&1"
                    let status = try ssh.execute(script) { log in
                        DispatchQueue.main.async {
                            logs += self.showProgress(log)
                        }
                    }

                    self.result[index] = status == 0 ? .Recovered : .Fail
                    self.result[index] = .Fail
                    if status != 22 {
                        self.errorLog += logs
                    }
                }
                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = false
                    self.progressView.isHidden = true
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                    self.dismissButton.isHidden = false
                    self.logButton.isHidden = self.errorLog == ""
                }
            } catch {
                self.showError(error)
            }
        }
    }
    
    private func showProgress(_ log: String) -> String {
        var cleanLog: [String] = []
        let splitLog = log.replacingOccurrences(of: "\r", with: "\n").split(separator: "\n").map { $0.trimmingCharacters(in: .newlines) }
        
        for logString in splitLog {
            let keyValue = logString.split(separator: ":")
            guard keyValue.count == 2 else {
                cleanLog.append(logString)
                continue
            }
            switch keyValue[0] {
            case "Save":
                progressType = "Recovery:"
                let value = keyValue[1].trimmingCharacters(in: .init(charactersIn: "%"))
                progressView.startProgress(to: CGFloat(Int(value) ?? 0), duration: 0.1)
            case "Check":
                progressType = "Check:"
                let value = keyValue[1].trimmingCharacters(in: .init(charactersIn: "%"))
                progressView.startProgress(to: CGFloat(Int(value) ?? 0), duration: 0.1)
            default:
                cleanLog.append(logString)
            }
        }
        return cleanLog.joined(separator: "\n")
    }
    
    private func deleteVideo(at indexPath: IndexPath) {
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let ssh = self.ssh else { return }
                let script = """
                echo \(password) | sudo -S echo START-SCRIPT
                sudo rm -rf \(self.entryList[indexPath.row]) 2>&1
                """
                let (status, log) = try ssh.capture(script)
                if status != 0 {
                    let error = SSH.ScriptError.scriptError(name: "Delete video", log: log)
                    self.showError(error)
                    return
                }
                DispatchQueue.main.async {
                    self.result[indexPath.row] = .Deleted
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            } catch {
                self.showError(error)
            }
        }
    }
    
    private func unhideVideo(at indexPath: IndexPath) {
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        let destPath = entryList[indexPath.row].replacingOccurrences(of: ".", with: "")
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let ssh = self.ssh else { return }
                let script = """
                echo \(password) | sudo -S echo START-SCRIPT
                sudo mv \(self.entryList[indexPath.row]) \(destPath) 2>&1
                """
                let (status, log) = try ssh.capture(script)
                if status != 0 {
                    let error = SSH.ScriptError.scriptError(name: "Unhide video", log: log)
                    self.showError(error)
                    return
                }
                DispatchQueue.main.async {
                    self.result[indexPath.row] = .Visible
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            } catch {
                self.showError(error)
            }
        }
    }

}

extension RecoveryVideoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entryList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecoveryVideoTableViewCell", for: indexPath) as! RecoveryVideoTableViewCell
        let fileSizeString = formater.string(fromByteCount: fileSize[indexPath.row])
        cell.fileInfoLabel.text = "\(indexPath.row): \(fileSizeString)"
        cell.resultLabel.text = result[indexPath.row].rawValue
        cell.resultLabel.textColor = result[indexPath.row].color
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard result[indexPath.row] == .Fail else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            self.deleteVideo(at: indexPath)
            completionHandler(false)
        }
        let unhideAction = UIContextualAction(style: .normal, title: "Unhide") { (action, sourceView, completionHandler) in
            self.unhideVideo(at: indexPath)
            completionHandler(true)
        }
        let actionsConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, unhideAction])
        actionsConfiguration.performsFirstActionWithFullSwipe = false
        return actionsConfiguration
    }
}

extension RecoveryVideoViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
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
