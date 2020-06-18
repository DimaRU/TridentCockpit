/////
////  KeychainService.swift
///   Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Foundation


enum KeychainService {
    private static let serviceName = Bundle.main.bundleIdentifier!
    
    private static func makeKeychainQuery(key: String) -> [String : AnyObject] {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        query[kSecAttrService as String] = KeychainService.serviceName as AnyObject
        query[kSecAttrAccount as String] = key as AnyObject
        
        return query
    }

    static func get(key: String) -> String? {
        var query = makeKeychainQuery(key: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        
        var queryResult: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &queryResult)
        guard status == noErr else { return nil }
        
        guard let item = queryResult as? [String : AnyObject],
            let data = item[kSecValueData as String] as? Data else { return nil }
        
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func set(_ string: String, key: String) -> Bool {
        let data = string.data(using: .utf8)
        let status: OSStatus
        if get(key: key) != nil {
            var attributesToUpdate: [String : AnyObject] = [:]
            attributesToUpdate[kSecValueData as String] = data as AnyObject
            
            let query = makeKeychainQuery(key: key)
            status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        } else {
            var item = makeKeychainQuery(key: key)
            item[kSecValueData as String] = data as AnyObject
            status = SecItemAdd(item as CFDictionary, nil)
        }
        return status == noErr
    }
    
    
    @discardableResult
    static func delete(key: String) -> Bool {
        let item = makeKeychainQuery(key: key)
        
        let status = SecItemDelete(item as CFDictionary)
        return status == noErr
    }

}
