/////
////  MulticastDelegate.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

class MulticastDelegate<T> {
    private let delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    let semaphore = DispatchSemaphore(value: 1)
    
    func add(_ delegate: T) {
        semaphore.wait()
        delegates.add(delegate as AnyObject)
        semaphore.signal()
    }

    func remove(_ delegateToRemove: T) {
        semaphore.wait()
        for delegate in delegates.allObjects {
            if delegate === delegateToRemove as AnyObject {
                delegates.remove(delegate)
            }
        }
        semaphore.signal()
    }

    func invoke(_ invocation: (T) -> Void) {
        semaphore.wait()
        let allObjects = delegates.allObjects
        semaphore.signal()
        for delegate in allObjects.reversed() {
            invocation(delegate as! T)
        }
    }
}
