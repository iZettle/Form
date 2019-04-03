//
//  UIView+Embedding.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-09-17.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UIView {
    /// Adds view as a subview to `self` and sets up constraints according to passed parameters.
    /// - Parameters:
    ///   - view: View to embed
    ///   - layoutArea: Area to guide layout, defaults to `.default`.
    ///   - edgeInsets: Insets from `self`, defaults to `.zero`.
    ///   - pinToEdges:  Edges to pin `view` to, defaults to `.all` If pinning is missing for one axis the view will be centered in that axis.
    ///   - layoutPriority: The priority to apply to all added constraints, defaults to `.required`
    ///   - disembedBag: Will add disembedding of views and constraints to bag if not nil.
    func embedView(_ view: UIView, withinLayoutArea layoutArea: ViewLayoutArea = .default, edgeInsets: UIEdgeInsets = UIEdgeInsets.zero, pinToEdges: UIRectEdge = .all, layoutPriority: UILayoutPriority = .required, disembedBag: DisposeBag? = nil) {
        let insets = edgeInsets
        if pinToEdges == .all {
            view.frame = bounds.inset(by: insets) // preset the frame to avoid an unnecessary relayout and unwanted animations
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        let layoutGuide = self.layoutGuide(for: layoutArea)
        var constraints = [NSLayoutConstraint]()

        if pinToEdges.intersection([.left, .right]).isEmpty { // Center X
            let centerXConstraint = view.centerXAnchor == layoutGuide.centerXAnchor + insets.left - insets.right
            let widthConstraint = view.widthAnchor <= layoutGuide.widthAnchor - (insets.left + insets.right)
            constraints += [centerXConstraint, widthConstraint]

        } else {
            if pinToEdges.contains(.left) {
                constraints += [view.leftAnchor == layoutGuide.leftAnchor + insets.left]
            } else if pinToEdges.contains(.right) {
                constraints += [view.leftAnchor >= layoutGuide.leftAnchor + insets.left]
            }

            if pinToEdges.contains(.right) {
                constraints += [view.rightAnchor == layoutGuide.rightAnchor - insets.right]
            } else if pinToEdges.contains(.left) {
                constraints += [view.rightAnchor <= layoutGuide.rightAnchor - insets.right]
            }
        }

        if pinToEdges.intersection([.top, .bottom]).isEmpty { // Center Y
            let centerYConstraint = view.centerYAnchor == layoutGuide.centerYAnchor + insets.top - insets.bottom
            let heightConstraint = view.heightAnchor <= layoutGuide.heightAnchor - (insets.top + insets.bottom)
            constraints += [centerYConstraint, heightConstraint]

        } else {
            if pinToEdges.contains(.top) {
                constraints += [view.topAnchor == layoutGuide.topAnchor + insets.top]
            } else if pinToEdges.contains(.bottom) {
                constraints += [view.topAnchor >= layoutGuide.topAnchor + insets.top]
            }

            if pinToEdges.contains(.bottom) {
                constraints += [view.bottomAnchor == layoutGuide.bottomAnchor - insets.bottom]
            } else if pinToEdges.contains(.top) {
                constraints += [view.bottomAnchor <= layoutGuide.bottomAnchor - insets.bottom]
            }
        }

        constraints.forEach { $0.priority = layoutPriority }
        activate(constraints)

        disembedBag += {
            deactivate(constraints)
            view.removeFromSuperview()
        }
    }

    /// Creates an instance with `view` embedded.
    ///   - layoutArea: Area to guide layout, defaults to `.default`.
    ///   - edgeInsets: Insets from `self`, defaults to `.zero`.
    ///   - pinToEdges:  Edges to pin `view` to, defaults to `.all` If pinning is missing for one axis the view will be centered in that axis.
    ///   - layoutPriority: The priority to apply to all added constraints, defaults to `.required`
    ///   - disembedBag: Will add disembedding of views and constraints to bag if not nil.
    convenience init(embeddedView view: UIView, withinLayoutArea layoutArea: ViewLayoutArea = .default, backgroundColor: UIColor = .clear, edgeInsets: UIEdgeInsets = UIEdgeInsets.zero, pinToEdges: UIRectEdge = .all, layoutPriority: UILayoutPriority = .required, disembedBag: DisposeBag? = nil) {
        self.init()
        self.backgroundColor = backgroundColor
        embedView(view, withinLayoutArea: layoutArea, edgeInsets: edgeInsets, pinToEdges: pinToEdges, layoutPriority: layoutPriority, disembedBag: disembedBag)
    }
}

public extension UIScrollView {
    /// Adds view as a subview to `self` and sets up constraints for the `scrollAxis`.
    func embedView(_ view: UIView, scrollAxis: NSLayoutConstraint.Axis) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        activate(
            topAnchor == view.topAnchor,
            bottomAnchor == view.bottomAnchor,
            leadingAnchor == view.leadingAnchor,
            trailingAnchor == view.trailingAnchor
        )

        switch scrollAxis {
        case .horizontal:
            activate(heightAnchor == view.heightAnchor)
        case .vertical:
            activate(widthAnchor == view.widthAnchor)
        @unknown default:
            assertionFailure("Unknown ScrollAxis")
        }
    }

    /// Creates a new instance with `view` added as a subview and constraints set up for the `scrollAxis`.
    convenience init(embeddedView view: UIView, scrollAxis: NSLayoutConstraint.Axis) {
        self.init()
        embedView(view, scrollAxis: scrollAxis)
    }
}

public extension UIView {
    /// Adds view as a subview to `self` and sets up autoresizingMask according to passed parameters.
    /// - Parameter view: View to embed
    /// - Parameter edgeInsets: Insets from `self`, defaults to `.zero`.
    /// - Parameter pinToEdges:  Edges to pin `view` to, defaults to `.all` If pinning is missing for one axis the view will be centered in that axis.
    func embedAutoresizingView(_ view: UIView, edgeInsets: UIEdgeInsets = UIEdgeInsets.zero, pinToEdges: UIRectEdge = .all) {
        var autoresizingMask: UIView.AutoresizingMask = []

        if pinToEdges.contains([ .left, .right]) {
            view.frame.origin.x = edgeInsets.left
            view.frame.size.width = bounds.size.width - edgeInsets.left - edgeInsets.right
            autoresizingMask.formUnion(.flexibleWidth)
        } else if pinToEdges.contains(.left) {
            view.frame.origin.x = edgeInsets.left
        } else if pinToEdges.contains(.right) {
            view.frame.origin.x = bounds.size.width - edgeInsets.right - view.bounds.size.width
        }

        if pinToEdges.contains([ .top, .bottom]) {
            view.frame.origin.y = edgeInsets.top
            view.frame.size.height = bounds.size.height - edgeInsets.top - edgeInsets.bottom
            autoresizingMask.formUnion(.flexibleHeight)
        } else if pinToEdges.contains(.top) {
            view.frame.origin.y = edgeInsets.top
        } else if pinToEdges.contains(.bottom) {
            view.frame.origin.y = bounds.size.height - edgeInsets.bottom - view.bounds.size.height
        }

        if !pinToEdges.contains(.left) {
            autoresizingMask.formUnion(.flexibleLeftMargin)
        }

        if !pinToEdges.contains(.right) {
            autoresizingMask.formUnion(.flexibleRightMargin)
        }

        if !pinToEdges.contains(.top) {
            autoresizingMask.formUnion(.flexibleTopMargin)
        }

        if !pinToEdges.contains(.bottom) {
            autoresizingMask.formUnion(.flexibleBottomMargin)
        }

        view.autoresizingMask = autoresizingMask
        addSubview(view)
    }

    /// Creates an instance with `view` embedded set up with autoresizingMask.
    /// - Parameter edgeInsets: Insets from `self`, defaults to `.zero`.
    /// - Parameter pinToEdges:  Edges to pin `view` to, defaults to `.all` If pinning is missing for one axis the view will be centered in that axis.
    convenience init(embeddedViewAutoresizingView view: UIView, backgroundColor: UIColor = .clear, edgeInsets: UIEdgeInsets = UIEdgeInsets.zero, pinToEdges: UIRectEdge = .all) {
        self.init()
        self.backgroundColor = backgroundColor
        embedAutoresizingView(view, edgeInsets: edgeInsets, pinToEdges: pinToEdges)
    }
}
