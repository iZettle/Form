//
//  AssociatedValues.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-08-26.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

extension NSObject {
    func associatedValue<T>(forKey key: UnsafeRawPointer) -> T? {
        return objc_getAssociatedObject(self, key) as? T
    }

    func associatedValue<T>(forKey key: UnsafeRawPointer,
                            shouldRetainInitial: Bool = true,
                            initial: @autoclosure () throws -> T) rethrows -> T {
        if let val: T = associatedValue(forKey: key) {
            return val
        }
        let val = try initial()
        setAssociatedValue(val, forKey: key, shouldBeRetained: shouldRetainInitial)
        return val
    }

    func setAssociatedValue<T>(_ val: T?, forKey key: UnsafeRawPointer, shouldBeRetained: Bool = true) {
        let associationPolicy: objc_AssociationPolicy = shouldBeRetained ? .OBJC_ASSOCIATION_RETAIN : .OBJC_ASSOCIATION_ASSIGN
        objc_setAssociatedObject(self, key, val, associationPolicy)
    }

    func clearAssociatedValue(forKey key: UnsafeRawPointer) {
        objc_setAssociatedObject(self, key, nil, .OBJC_ASSOCIATION_RETAIN)
    }
}
