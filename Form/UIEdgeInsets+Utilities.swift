//
//  UIEdgeInsets+Utilities.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-12-09.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UIEdgeInsets {
    /// Creates a new instance with all insets set to `inset`.
    init(inset: CGFloat) {
        self.init(horizontalInset: inset, verticalInset: inset)
    }

    /// Creates a new instance with `left` and `right` set to `horizontalInset` and `top` and `bottom` set to `verticalInset`.
    init(horizontalInset: CGFloat, verticalInset: CGFloat) {
        self.init(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

    /// Sets `top` and `bottom` set to `verticalInset`.
    mutating func set(verticalInset inset: CGFloat) {
        top = inset
        bottom = inset
    }

    /// Sets `left` and `right` to `horizontalInset`.
    mutating func set(horizontalInset inset: CGFloat) {
        left = inset
        right = inset
    }

    static func += (lhs: inout UIEdgeInsets, rhs: UIEdgeInsets) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout UIEdgeInsets, rhs: UIEdgeInsets) {
        lhs = lhs - rhs
    }
}

/// Returns a new edge insets with components set as the sum of `lhs` and `rhs` components, respectively.
public func + (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: lhs.top + rhs.top, left: lhs.left + rhs.left, bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
}

/// Returns a new edge insets with components set as the difference of `lhs` and `rhs` components, respectively.
public func - (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: lhs.top - rhs.top, left: lhs.left - rhs.left, bottom: lhs.bottom - rhs.bottom, right: lhs.right - rhs.right)
}
