//
//  SubviewOrderable.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-27.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Conforming types provides a mutable ordering of views.
public protocol SubviewOrderable: class {
    var orderedViews: [UIView] { get set }
}

public extension SubviewOrderable {
    @discardableResult
    func append<V: UIView>(_ view: V) -> Self {
        orderedViews.append(view)
        return self
    }

    @discardableResult
    func prepend(_ view: UIView) -> Self {
        orderedViews.insert(view, at: 0)
        return self
    }
}

public extension SubviewOrderable {
    @discardableResult
    func append(_ image: UIImage) -> Self {
        return append(UIImageView(image: image))
    }

    @discardableResult
    func prepend(_ image: UIImage) -> Self {
        return prepend(UIImageView(image: image))
    }

    @discardableResult
    func append(_ image: UIImage, minWidth: CGFloat, pinToEdges: UIRectEdge = []) -> Self {
        return append(UIView(image: image, minWidth: minWidth, pinToEdges: pinToEdges))
    }

    @discardableResult
    func prepend(_ image: UIImage, minWidth: CGFloat, pinToEdges: UIRectEdge = []) -> Self {
        return prepend(UIView(image: image, minWidth: minWidth, pinToEdges: pinToEdges))
    }

    @discardableResult
    func append(_ title: String, style: TextStyle = .defaultDetail) -> Self {
        return append(UILabel(value: title, style: style))
    }

    @discardableResult
    func prepend(_ title: String, style: TextStyle = .defaultDetail) -> Self {
        return prepend(UILabel(value: title, style: style))
    }
}

private extension UIView {
    convenience init(image: UIImage, minWidth: CGFloat, pinToEdges: UIRectEdge = []) {
        self.init(embeddedView: UIImageView(image: image), pinToEdges: pinToEdges)
        activate(widthAnchor >= minWidth)
        activate(widthAnchor == minWidth).priority = .defaultLow
    }
}
