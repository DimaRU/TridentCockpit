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
    
    func message() -> String {
        switch self {
        case .responceSyntaxError(let message):
            return message
        case .serverError(let code):
            return "code \(code)"
        case .unaviable,
             .notFound:
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
        }
    }
    
}
