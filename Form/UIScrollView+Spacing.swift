//
//  UIScrollView+Spacing.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-08-31.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UIScrollView {
    /// Will evenly add spacing between the `orderedViews` to fill out any empty space in the scroll view.
    /// The height of the added spacing will be dynamically updated to react on layout changes.
    // - Parameter disembedBag: Will add disembedding of views and constraints to bag in not nil.
    // - Returns: A disposable that upon disposal will end the the dynamic update of added spacing.
    func embedWithSpacingBetween(_ orderedViews: [UIView], disembedBag: DisposeBag? = nil) -> Disposable {
        let bag = DisposeBag()

        let stack = UIStackView(views: orderedViews, axis: .vertical)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .equalSpacing
        stack.alignment = .fill
        addSubview(stack)

        let bottom: NSLayoutConstraint
        let constraints: [NSLayoutConstraint]
        if #available(iOS 11, *) {
            bottom = frameLayoutGuide.heightAnchor <= stack.heightAnchor
            constraints = [
                contentLayoutGuide.topAnchor == stack.topAnchor,
                contentLayoutGuide.bottomAnchor == stack.bottomAnchor,
                bottom,
                leftAnchor == stack.leftAnchor,
                rightAnchor == stack.rightAnchor,
                widthAnchor == stack.widthAnchor,
            ] as [NSLayoutConstraint]
        } else {
            bottom = layoutMarginsGuide.bottomAnchor == stack.bottomAnchor
            constraints = [
                topAnchor == stack.topAnchor,
                bottomAnchor == stack.bottomAnchor,
                bottom,
                leftAnchor == stack.leftAnchor,
                rightAnchor == stack.rightAnchor,
                widthAnchor == stack.widthAnchor,
            ] as [NSLayoutConstraint]
        }

        bottom.priority = .defaultLow
        bag += signal(for: \.contentInset)[\.bottom].distinct().atOnce().onValue {
            bottom.constant = $0
        }

        // The added constraints need to be activated before any calls to `layoutIfNeeded` because the layout might be unsatisfiable otherwise
        activate(constraints)
        disembedBag += { deactivate(constraints) }

        // .equalSpacing gives ambigious layout on iOS < 11, help out by calculating spacing manually.
        if #available(iOS 11, *) {} else if orderedViews.count > 0 {
            let contentHeight = signal(for: \.contentSize)[\.height].toVoid().atValue {
                for view in orderedViews { view.layoutIfNeeded() }
            }.map {
                return orderedViews.reduce(0) { height, view in height + view.bounds.height }
            }

            let emptySpaceHeight = signal(for: \.contentInset).map { inset in
                self.bounds.height - inset.top - inset.bottom
            }

            bag += combineLatest(emptySpaceHeight, contentHeight)
                .map { emptySpaceHeight, contentHeight in
                    max(0, emptySpaceHeight - contentHeight)/CGFloat(orderedViews.count - 1)
                }.distinct().atOnce().onValue { spacing in
                    stack.spacing = spacing
                    self.layoutIfNeeded()
            }
        }

        return bag
    }
}
