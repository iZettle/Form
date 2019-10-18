//
//  SeparatorStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-10-22.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public struct SeparatorStyle: Style {
    public var width: CGFloat
    public var color: UIColor

    public init(width: CGFloat, color: UIColor) {
        self.width = width
        self.color = color
    }
}

public extension SeparatorStyle {
    static let none = SeparatorStyle(width: 0, color: .clear)
}

public extension InsettedStyle where Style == SeparatorStyle {
    static let none = InsettedStyle(style: .none, insets: .zero)
}

public extension UIView {
    /// Creates a new instance layed-out as a `axis` separator and styled by `style`
    convenience init(axis: NSLayoutConstraint.Axis, style: SeparatorStyle) {
        self.init(color: style.color)
        translatesAutoresizingMaskIntoConstraints = false
        activate((axis == .horizontal ? widthAnchor : heightAnchor) == style.width)
    }
}

public extension Sequence where Iterator.Element == UIView {
    /// Returns a new array of views where separator views produced by `separator` as been injected between `self`s views.
    func injectedWithView(_ separator: @autoclosure () -> UIView) -> [UIView] {
        var views = Array(self)
        for i in (1..<views.count).reversed() {
            views.insert(separator(), at: i)
        }
        return views
    }

    /// Returns a new array of views where separator of `axis` and `style` as been injected between `self`s views.
    func injectedWithSeparator(axis: NSLayoutConstraint.Axis, style: SeparatorStyle) -> [UIView] {
        return injectedWithView(UIView(axis: axis, style: style))
    }

    /// Returns a new array of views where separator of `axis` and `style` as been injected between `self`s views.
    func injectedWithSeparator(axis: NSLayoutConstraint.Axis, style: InsettedStyle<SeparatorStyle>) -> [UIView] {
        return injectedWithView(UIView(embeddedView: UIView(axis: axis, style: style.style), edgeInsets: style.insets))
    }
}

public extension UIScreen {
    /// Returns the thinnest line representable on `self`.
    var hairlineWidth: CGFloat {
        return 1.0 / scale
    }
}

public extension UITraitCollection {
    /// Returns the thinnest line representable on the current used trait's screen, or the main screen in `self`'s displayScale is not defined.
    var hairlineWidth: CGFloat {
        return displayScale > 0 ? 1.0 / displayScale : UIScreen.main.hairlineWidth
    }

    /// Returns true if horizontal size class is `.regular`
    var isRegular: Bool { return horizontalSizeClass == .regular }

    /// Returns true if horizontal size class is `.compact`
    var isCompact: Bool { return horizontalSizeClass == .compact }
}

// Deprecated
public extension UITraitCollection {

    @available(*, deprecated, message: "No longer supported as a convenience variable. Prefer size class checks (isRegular/isCompact) or check the userInterfaceIdiom manually")
    var isPad: Bool { return userInterfaceIdiom == .pad }

    @available(*, deprecated, message: "No longer supported as a convenience variable. Prefer size class checks (isRegular/isCompact) or check the userInterfaceIdiom manually")
    var isPhone: Bool { return userInterfaceIdiom == .phone }

}

public extension CGFloat {
    /// Returns the thinnest line representable by the main screen.
    static var hairlineWidth: CGFloat {
        return UIScreen.main.hairlineWidth
    }
}
