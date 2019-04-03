//
//  KeyboardAnimation.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-12-02.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public struct KeyboardAnimation {
    public var duration: TimeInterval
    public var curve: UIView.AnimationCurve

    public init(duration: TimeInterval, curve: UIView.AnimationCurve) {
        self.duration = duration
        self.curve = curve
    }
}

public extension KeyboardAnimation {
    /// Returns true if duration is larger than zero.
    var willAnimate: Bool {
        return duration > 0
    }

    /// Perform `animations` in an animation block using `self`'s parameters and the provided `options`.
    /// - Note: if willAnimate is false, `animations` won't be called in an animation block.
    func animate(_ options: UIView.AnimationOptions = .allowUserInteraction, animations: @escaping () -> Void) {
        if willAnimate {
            UIView.animate(withDuration: duration, delay: 0, options: [curve.animationOptions, options], animations: animations, completion: nil)
        } else {
            animations()
        }
    }
}

public extension KeyboardAnimation {
    static let none = KeyboardAnimation(duration: 0, curve: .easeInOut)
}

private extension UIView.AnimationCurve {
    var animationOptions: UIView.AnimationOptions {
        switch self {
        case .easeIn: return .curveEaseIn
        case .easeOut: return .curveEaseOut
        case .easeInOut: return UIView.AnimationOptions()
        case .linear: return .curveLinear
        @unknown default:
            assertionFailure("Unknown UIView.AnimationCurve")
            return .curveLinear
        }
    }
}
