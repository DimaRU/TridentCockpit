/////
////  SSHCommand+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import PromiseKit
import SwiftSH

extension SSHError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown                          : return "Unknown"
        case .bannerReceive                    : return "Banner Receive"
        case .bannerSend                       : return "Banner Send"
        case .invalidMessageAuthenticationCode : return "Invalid Message Authentication Code"
        case .decrypt                          : return "Decrypt"
        case .methodNone                       : return "Method None"
        case .requestDenied                    : return "Request Denied"
        case .methodNotSupported               : return "Method Not Supported"
        case .invalid                          : return "Invalid"
        case .agentProtocol                    : return "Agent Protocol"
        case .encrypt                          : return "Encrypt"
        case .allocation                       : return "Allocation"
        case .timeout                          : return "Timeout"
        case .protocol                         : return "Protocol"
        case .again                            : return "Again"
        case .bufferTooSmall                   : return "Buffer Too Small"
        case .badUse                           : return "Bad Use"
        case .compress                         : return "Compress"
        case .outOfBoundary                    : return "Out Of Boundary"
        case .alreadyConnected                 : return "Already Connected"
        case .hostResolutionFailed             : return "Host Resolution Failed"
        case .keyExchangeFailure               : return "Key Exchange Failure"
        case .hostkey                          : return "Hostkey"
        case .authenticationFailed             : return "Authentication Failed"
        case .passwordExpired                  : return "Password Expired"
        case .publicKeyUnverified              : return "Public Key Unverified"
        case .publicKeyProtocol                : return "Public Key Protocol"
        case .publicKeyFile                    : return "Public Key File"
        case .unsupportedAuthenticationMethod  : return "Unsupported Authentication Method"
        case .knownHosts                       : return "Known Hosts"
        }
    }
    
}
extension SSHCommand {
    enum SSHScriptError: Error, LocalizedError {
        case scriptError(name: String, log: String)
        
        var errorDescription: String? {
            switch self {
            case .scriptError(name: let name, log: _):
                return "Error while execute \(name)"
            }
        }
        
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
        let redirectPorts = Gopro3API.redirectPorts
        let login = GlobalParams.rovLogin
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!
        
        var header = "#/bin/bash\n"
        header += "echo \(password) | sudo -S echo START-SCRIPT\n"
        header += "exec 2>&1\n"
        header += "SOURCEIP=\(FastRTPS.localAddress)\n"
        header += "BASEPORT=\(basePort)\n"
        header += "REDIRECTPORTS=(\(redirectPorts))\n"

        self.timeout = 10
        self.connect()
            .authenticate(.byPassword(username: login, password: password))
            .execute(header+scriptBody) { (command, log: String?, error) in
                self.disconnect {}
                if let log = log {
                    let logStrings = log.split(separator: "\n")
                    if logStrings.last != "OK-SCRIPT" {
                        let fileredLog = logStrings.filter{ !$0.contains("sudo: unable to resolve host") && !$0.contains("START-SCRIPT") }.reduce("") { $0 + $1 + "\n"}
                        seal.reject(SSHScriptError.scriptError(name: name, log: fileredLog))
                    } else {
                        seal.fulfill(())
                    }
                } else {
                    seal.reject(error!)
                }
        }
        return promise
    }
    
    func executeCommand(_ command: String) -> Promise<[String]> {
        let (promise, seal) = Promise<[String]>.pending()
        let login = GlobalParams.rovLogin
        let passwordBase64 = GlobalParams.rovPassword
        let password = String(data: Data(base64Encoded: passwordBase64)!, encoding: .utf8)!

        self.timeout = 5
        self.connect()
            .authenticate(.byPassword(username: login, password: password))
            .execute(command) { (returnCommand, log: String?, error) in
                if let log = log {
                    let logStrings = (log.split(separator: "\n")).map{ String($0) }
                    seal.fulfill(logStrings)
                } else {
                    seal.reject(error!)
                }
                self.disconnect {}
        }
        return promise
    }
}
