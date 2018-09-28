//
//  UIView+Layout.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-09-17.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UIView {
    /// Creates an instance with the height constrained to `height`
    convenience init(height: CGFloat) {
        self.init()
        activate(heightAnchor == height)
    }

    /// Creates an instance with the width constrained to `width`
    convenience init(width: CGFloat) {
        self.init()
        activate(widthAnchor == width)
    }
}

public extension UIView {
    /// Creates an instance with the background color set to `color`
    convenience init(color: UIColor) {
        self.init()
        backgroundColor = color
    }
}

public extension UIView {
    /// A view the low compression resistance useful for providing spacing between views.
    static var spacer: UIView {
        let spacer = UIView()
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return spacer
    }
}

public extension UIView {
    /// Animate the update of value at `keyPath` using a duration of 0.3 seconds.
    ///
    ///     view[animated: \.alpha] = 1
    subscript<Value>(animated keyPath: ReferenceWritableKeyPath<UIView, Value>) -> Value {
        get {
            return self[keyPath: keyPath]
        }
        set {
            guard self.window != nil else {
                self[keyPath: keyPath] = newValue
                return
            }

            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                self[keyPath: keyPath] = newValue
            })
        }
    }
}
