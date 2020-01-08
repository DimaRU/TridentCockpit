/////
////  NetworkError.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case notFound
    case responceSyntaxError(message: String)
    case serverError(code: Int)
    case unaviable
    case gone
    case unprovisioned
    
    func message() -> String {
        switch self {
        case .responceSyntaxError(let message):
            return message
        case .serverError(let code):
            return "Error code \(code)"
        case .unaviable,
             .notFound,
             .gone,
             .unprovisioned:
            return ""
        }
    }
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notFound:
            return NSLocalizedString("Resource not found", comment: "Network error")
        case .responceSyntaxError:
            return NSLocalizedString("Responce syntax error", comment: "Network error")
        case .serverError:
            return NSLocalizedString("Server error", comment: "Network error")
        case .unaviable:
            return NSLocalizedString("Network unaviable", comment: "Network error")
        case .gone:
            return NSLocalizedString("Device off power", comment: "Network error")
        case .unprovisioned:
            return NSLocalizedString("Device unprovisioned", comment: "Network error")
        }
    }
    
}
