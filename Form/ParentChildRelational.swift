//
//  ParentChildRelational.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-09-17.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public protocol ParentChildRelational {
    associatedtype Member: ParentChildRelational where Member.Member == Member
    var parent: Member? { get }
    var children: [Member] { get }
}

extension UIView: ParentChildRelational {
    public var parent: UIView? { return superview }
    public var children: [UIView] { return subviews }
}

extension UIViewController: ParentChildRelational {
}

extension CALayer: ParentChildRelational {
    public var parent: CALayer? { return superlayer }
    public var children: [CALayer] { return sublayers ?? [] }
}

public extension ParentChildRelational {
    /// Returns all descendant members.
    var allDescendants: AnySequence<Member> {
        return AnySequence { () -> AnyIterator<Member> in
            var children = self.children.makeIterator()
            var childDesendants: AnyIterator<Member>?
            return AnyIterator {
                if let desendants = childDesendants, let next = desendants.next() {
                    return next
                }

                guard let next = children.next() else { return nil }

                childDesendants = next.allDescendants.makeIterator()
                return next
            }
        }
    }

    /// Returns all descendant members of type `type`.
    func allDescendants<T>(ofType type: T.Type) -> AnySequence<T> {
        return AnySequence(allDescendants.lazy.compactMap { $0 as? T })
    }

    /// Returns all descendant members of class `class`.
    func allDescendants(ofClass class: AnyClass) -> AnySequence<Member> {
        let className = "\(`class`)"
        let classRange = className.startIndex..<className.endIndex
        return AnySequence(allDescendants.lazy.filter {
            let name = "\(type(of: $0))"
            guard let range = name.range(of: className), !range.isEmpty else { return false }

            if range == classRange {
                return true
            }

            /// Make sure to handle views that has been setup for KVO as well.
            if range.upperBound == name.endIndex && name.hasPrefix("NSKVONotifying_") {
                return true
            }

            return false
        })
    }

    /// Returns all descendant members of class named `name`.
    func allDescendants(ofClassNamed name: String) -> AnySequence<Member> {
        return allDescendants(ofClass: NSClassFromString(name)!)
    }

    /// Returns all ancestors sorted from the closest to the farthest.
    var allAncestors: AnySequence<Member> {
        return AnySequence { () -> AnyIterator<Member> in
            var parent = self.parent
            return AnyIterator {
                defer { parent = parent?.parent }
                return parent
            }
        }
    }

    ///Returns the first ancestor of type `type` if any.
    func firstAncestor<T>(ofType type: T.Type) -> T? {
        guard let parent = parent else { return nil }
        if let matching = parent as? T {
            return matching
        }
        return parent.firstAncestor(ofType: type)
    }
}

public extension ParentChildRelational where Member == Self {
    /// Returns the root member of `self`.
    var rootParent: Member {
        return parent?.rootParent ?? self
    }
}

public extension ParentChildRelational where Member: Equatable {
    /// Returns all ancestors that are decendant to `member`, sorted from the closest to the farthest.
    /// - Note: If `member` is not found, nil is returned.
    func allAncestors(descendantsOf member: Member) -> AnySequence<Member>? {
        var found = false
        let result = allAncestors.prefix { found = $0 == member; return !found }
        return found ? AnySequence(result) : nil
    }

    /// Returns the closest common ancestor of `self` and `other` if any.
    func closestCommonAncestor(with other: Member) -> Member? {
        let common = self.allAncestors.filter(other.allAncestors.contains)
        return common.first
    }
}

public extension UIView {
    /// Returns the first found view controller if any, walking up the responder chain.
    var viewController: UIViewController? {
        if let vc = next as? UIViewController {
            return vc
        } else {
            return superview?.viewController
        }
    }
}

public extension UIView {
    /// Returns the frame of `self` in the `rootView`s coordinate system.
    var absoluteFrame: CGRect {
        return convert(bounds, to: rootView)
    }

    /// Returns the root view of `self`.
    var rootView: UIView {
        return window ?? superview?.rootView ?? self
    }
}
