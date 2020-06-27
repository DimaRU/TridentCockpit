/////
////  MulticastDelegate.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

class MulticastDelegate<T> {
    private let delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    func add(_ delegate: T) {
        objc_sync_enter(delegates)
        delegates.add(delegate as AnyObject)
        objc_sync_exit(delegates)
    }

    func remove(_ delegateToRemove: T) {
        objc_sync_enter(delegates)
        for delegate in delegates.allObjects {
            if delegate === delegateToRemove as AnyObject {
                delegates.remove(delegate)
            }
        }
        objc_sync_exit(delegates)
    }

    func invoke(_ invocation: (T) -> Void) {
        autoreleasepool {
            for delegate in delegates.allObjects.reversed() {
                invocation(delegate as! T)
            }
        }
    }
}
