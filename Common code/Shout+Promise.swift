/////
////  Shout+Promise.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import PromiseKit
import Shout

extension SSH {
    enum ScriptError: Error, LocalizedError {
        case scriptError(name: String, log: String)
        
        var errorDescription: String? {
            switch self {
            case .scriptError(name: let name, log: _):
                return "Error while execute \(name)"
            }
        }
        
        var failureReason: String? {
            switch self {
            case .scriptError(name: _, log: let log):
                return log
            }
        }
    }
    
    
    static public func executeCommand(_ command: String) -> Promise<[String]> {
        return SSHProxy().executeCommand(command)
    }
    static public func executeScript(name: String) -> Promise<Void> {
        return SSHProxy().executeScript(name: name)
    }

}

class SSHProxy {
    private var ssh: SSH?
    
    func executeCommand(_ command: String) -> Promise<[String]> {
        let (promise, seal) = Promise<[String]>.pending()
        let login = GlobalParams.rovLogin
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.ssh = try SSH(host: FastRTPS.remoteAddress, numericHost: true)
                try self.ssh!.authenticate(username: login, password: password)
                let (status, output) = try self.ssh!.capture(command)
                self.ssh = nil
                if status == 0 {
                    let logStrings = (output.split(separator: "\n")).map{ String($0) }
                    seal.fulfill(logStrings)
                } else {
                    let error = SSH.ScriptError.scriptError(name: "command", log: output)
                    seal.reject(error)
                }
            } catch {
                self.ssh = nil
                seal.reject(error)
            }
        }
        return promise
    }
    
    
    func executeScript(name: String) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        guard let url = Bundle.main.url(forResource: name, withExtension: "sh") else {
            fatalError("Not found: \(name).sh")
        }
        guard let scriptBody = try? String(contentsOf: url) else {
            fatalError("Can't load \(url)")
        }
        
        let basePort = GlobalParams.basePort
        let redirectPorts = "80 8080"
        let login = GlobalParams.rovLogin
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        
        var header = "#/bin/bash\n"
        header += "echo \(password) | sudo -S echo START-SCRIPT\n"
        header += "exec 2>&1\n"
        header += "SOURCEIP=\(FastRTPS.localAddress)\n"
        header += "BASEPORT=\(basePort)\n"
        header += "REDIRECTPORTS=(\(redirectPorts))\n"
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.ssh = try SSH(host: FastRTPS.remoteAddress, numericHost: true)
                try self.ssh!.authenticate(username: login, password: password)
                let (status, output) = try self.ssh!.capture(header+scriptBody)
                self.ssh = nil
                let logStrings = (output.split(separator: "\n")).map{ String($0) }

                if status == 0, logStrings.last == "OK-SCRIPT" {
                    seal.fulfill(())
                } else {
                    let fileredLog = logStrings.filter{ !$0.contains("sudo: unable to resolve host") && !$0.contains("START-SCRIPT") }.reduce("") { $0 + $1 + "\n"}
                    seal.reject(SSH.ScriptError.scriptError(name: name, log: fileredLog))
                }
            } catch {
                self.ssh = nil
                seal.reject(error)
            }
        }
        return promise
    }
}
