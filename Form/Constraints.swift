//
//  Constraints.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-11-27.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit

/// Help protocol to allow carrying around constants and multipliers
/// This will allow you to use operator to build your constraints:
///
///     let constraint = rightView.leftAnchor == leftView.rightAnchor + 10 // add 10 points spacing between views
///     let constraint = view.widthAnchor == 16/9*view.heightAnchor // 16/9 aspect
///     let constraints = [parent.heightAnchor == 400, parent.heightAnchor == parent.widthAnchor] // 400x400
public protocol Anchor {
    associatedtype LayoutAnchor
    var anchor: LayoutAnchor { get }
    var constant: CGFloat { get }
    var multiplier: CGFloat { get }
}

public extension Anchor {
    var constant: CGFloat { return 0 }
    var multiplier: CGFloat { return 1 }
}

extension NSLayoutYAxisAnchor: Anchor {
    public var anchor: NSLayoutYAxisAnchor { return self }
}

extension NSLayoutXAxisAnchor: Anchor {
    public var anchor: NSLayoutXAxisAnchor { return self }
}

extension NSLayoutDimension: Anchor {
    public var anchor: NSLayoutDimension { return self }
}

/// AdjustedAnchor carries around adjustments of the constant and multiplier between anchors of the same axis
public struct AdjustedAnchor<LayoutAnchor>: Anchor {
    public var anchor: LayoutAnchor
    public var constant: CGFloat
    public var multiplier: CGFloat

    fileprivate init(anchor: LayoutAnchor, constant: CGFloat, multiplier: CGFloat = 1) {
        self.anchor = anchor
        self.constant = constant
        self.multiplier = multiplier
    }
}

public func +<A: Anchor>(anchor: A, constant: CGFloat) -> AdjustedAnchor<A.LayoutAnchor> {
    return AdjustedAnchor(anchor: anchor.anchor, constant: anchor.constant + constant)
}

public func +<A: Anchor>(constant: CGFloat, anchor: A) -> AdjustedAnchor<A.LayoutAnchor> {
    return anchor + constant
}

public func -<A: Anchor>(anchor: A, constant: CGFloat) -> AdjustedAnchor<A.LayoutAnchor> {
    return AdjustedAnchor(anchor: anchor.anchor, constant: anchor.constant - constant)
}

public func *<A: Anchor>(anchor: A, multiplier: CGFloat) -> AdjustedAnchor<A.LayoutAnchor> where A.LayoutAnchor == NSLayoutDimension {
    return AdjustedAnchor(anchor: anchor.anchor, constant: anchor.constant, multiplier: anchor.multiplier*multiplier)
}

public func *<A: Anchor>(multiplier: CGFloat, anchor: A) -> AdjustedAnchor<A.LayoutAnchor> where A.LayoutAnchor == NSLayoutDimension {
    return anchor*multiplier
}

public func /<A: Anchor>(anchor: A, divisor: CGFloat) -> AdjustedAnchor<A.LayoutAnchor> where A.LayoutAnchor == NSLayoutDimension {
    return AdjustedAnchor(anchor: anchor.anchor, constant: anchor.constant, multiplier: anchor.multiplier/divisor)
}

public func ==<L: Anchor, R: Anchor, LayoutAnchor>(lhs: L, rhs: R) -> NSLayoutConstraint where L.LayoutAnchor == R.LayoutAnchor, L.LayoutAnchor: NSLayoutAnchor<LayoutAnchor> {
    return lhs.anchor.constraint(equalTo: rhs.anchor, constant: rhs.constant - lhs.constant)
}

public func >=<L: Anchor, R: Anchor, LayoutAnchor>(lhs: L, rhs: R) -> NSLayoutConstraint where L.LayoutAnchor == R.LayoutAnchor, L.LayoutAnchor: NSLayoutAnchor<LayoutAnchor> {
    return lhs.anchor.constraint(greaterThanOrEqualTo: rhs.anchor, constant: rhs.constant - lhs.constant)
}

public func <=<L: Anchor, R: Anchor, LayoutAnchor>(lhs: L, rhs: R) -> NSLayoutConstraint where L.LayoutAnchor == R.LayoutAnchor, L.LayoutAnchor: NSLayoutAnchor<LayoutAnchor> {
    return lhs.anchor.constraint(lessThanOrEqualTo: rhs.anchor, constant: rhs.constant - lhs.constant)
}

public func ==<L: Anchor, R: Anchor>(lhs: L, rhs: R) -> NSLayoutConstraint where L.LayoutAnchor == NSLayoutDimension, R.LayoutAnchor == NSLayoutDimension {
    return lhs.anchor.constraint(equalTo: rhs.anchor, multiplier: rhs.multiplier/lhs.multiplier, constant: rhs.constant - lhs.constant)
}

public func >=<L: Anchor, R: Anchor>(lhs: L, rhs: R) -> NSLayoutConstraint where L.LayoutAnchor == NSLayoutDimension, R.LayoutAnchor == NSLayoutDimension {
    return lhs.anchor.constraint(greaterThanOrEqualTo: rhs.anchor, multiplier: rhs.multiplier/lhs.multiplier, constant: rhs.constant - lhs.constant)
}

public func <=<L: Anchor, R: Anchor>(lhs: L, rhs: R) -> NSLayoutConstraint where L.LayoutAnchor == NSLayoutDimension, R.LayoutAnchor == NSLayoutDimension {
    return lhs.anchor.constraint(lessThanOrEqualTo: rhs.anchor, multiplier: rhs.multiplier/lhs.multiplier, constant: rhs.constant - lhs.constant)
}

public func ==<A: Anchor>(anchor: A, constant: CGFloat) -> NSLayoutConstraint where A.LayoutAnchor == NSLayoutDimension {
    return anchor.anchor.constraint(equalToConstant: constant)
}

public func >=<A: Anchor>(anchor: A, constant: CGFloat) -> NSLayoutConstraint where A.LayoutAnchor == NSLayoutDimension {
    return anchor.anchor.constraint(greaterThanOrEqualToConstant: constant)
}

public func <=<A: Anchor>(anchor: A, constant: CGFloat) -> NSLayoutConstraint where A.LayoutAnchor == NSLayoutDimension {
    return anchor.anchor.constraint(lessThanOrEqualToConstant: constant)
}

/// Activates each constraint in `constraints`
///
///     activate(rightView.leftAnchor == leftView.rightAnchor + 10, rightView.firstBaselineAnchor == firstBaselineAnchor)
@discardableResult
public func activate(_ constraints: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
    NSLayoutConstraint.activate(constraints)
    return constraints
}

/// Activates each constraint in `constraints`
@discardableResult
public func activate(_ constraints: NSLayoutConstraint...) -> [NSLayoutConstraint] {
    return activate(constraints)
}

/// Activates `constraint`
@discardableResult
public func activate(_ constraint: NSLayoutConstraint) -> NSLayoutConstraint {
    return activate(constraint)[0]
}

/// Deactivates each constraint in `constraints`
public func deactivate(_ constraints: [NSLayoutConstraint]) {
    NSLayoutConstraint.deactivate(constraints)
}

/// Deactivates each constraint in `constraints`
public func deactivate(_ constraints: NSLayoutConstraint...) {
    deactivate(constraints)
}

public func - (lhs: UILayoutPriority, rhs: Float) -> UILayoutPriority {
    return UILayoutPriority(rawValue: lhs.rawValue - rhs)
}

public func -= (lhs: inout UILayoutPriority, rhs: Float) {
    lhs = lhs-rhs
}

public func + (lhs: UILayoutPriority, rhs: Float) -> UILayoutPriority {
    return UILayoutPriority(rawValue: lhs.rawValue + rhs)
}

public func += (lhs: inout UILayoutPriority, rhs: Float) {
    lhs = lhs+rhs
}
