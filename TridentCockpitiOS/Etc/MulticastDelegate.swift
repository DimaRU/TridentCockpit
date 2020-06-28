/////
////  MulticastDelegate.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

class MulticastDelegate<T> {
    private var delegates: [T] = []
    
    deinit {
        delegates.removeAll()
    }

    func add(_ delegate: T) {
        objc_sync_enter(delegates)
        delegates.append(delegate)
        objc_sync_exit(delegates)
    }

    func remove(_ delegateToRemove: T) {
        objc_sync_enter(delegates)
        delegates.removeAll(where: { $0 as AnyObject === delegateToRemove as AnyObject })
        objc_sync_exit(delegates)
    }

    func invoke(_ invocation: (T) -> Void) {
        for delegate in delegates {
            invocation(delegate)
        }
    }
}
