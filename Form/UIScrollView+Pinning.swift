//
//  UIScrollView+Pinning.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-10-26.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UIScrollView {
    enum PinEdge: CaseIterable {
        case bottom
        case top
    }

    enum Pinning: CaseIterable {
        case loose /// When scrolling the pinned view will follow along
        case spring /// As loose but the view won't create any gap between the edge and itself
        case fixed /// The pinned view will stay fixed at the top or bottom
    }

    /// Will add `view` to the scroll view and keep it pinned to `edge`.
    /// - Parameters:
    ///   - view: the view to embed and keep pinned.
    ///   - edge: The edge to pin to.
    ///   - minHeight: Used as a minimum height of the `view` for `fixed` pinning and as exact height otherwise.
    ///   - pinning: The pinning behaviour (defaults to `.fixed`).
    ///   - adjustForInsets: If true the view will be adjusted for current insets such as keyboard.
    ///   - disembedBag: Will add disembedding of views and constraints to bag if not nil.
    func embedPinned(_ view: UIView, edge: PinEdge, minHeight: CGFloat, pinning: Pinning = .fixed, adjustForInsets: Bool = true, disembedBag: DisposeBag? = nil) -> Disposable {
        guard #available(iOS 11, *) else {
            return legacyEmbedPinned(view, edge: edge, minHeight: minHeight, pinning: pinning, adjustForInsets: adjustForInsets, disembedBag: disembedBag)
        }

        precondition(minHeight > 0)

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        let heightConstraint: NSLayoutConstraint
        let viewHeight: ReadSignal<CGFloat>

        if case .fixed = pinning {
            heightConstraint = (view.heightAnchor >= minHeight)
            viewHeight = view.signal(for: \.bounds)[\.size].distinct().map { $0.height }
        } else {
            heightConstraint = (view.heightAnchor == minHeight)
            viewHeight = ReadSignal(minHeight)
        }

        var constraints: [NSLayoutConstraint] = [
            heightConstraint,
            view.widthAnchor == widthAnchor,
            view.leftAnchor == leftAnchor,
            view.rightAnchor == rightAnchor
        ]

        let bag = DisposeBag()
        let insetKey = "embedPinned"

        let fix: NSLayoutConstraint?
        let spring: NSLayoutConstraint?

        switch edge {
        case .bottom:
            precondition(self[insets: insetKey].bottom == 0, "Only one view can be pinned to bottom")
            bag += viewHeight.atOnce().onValue { height in
                self[insets: insetKey].bottom = height
            }

            disembedBag += { self[insets: insetKey].bottom = 0 }

            switch pinning {
            case .spring:
                fix = frameLayoutGuide.bottomAnchor == view.bottomAnchor
                spring = view.topAnchor >= topAnchor
                fix?.priority -= 1
            case .fixed:
                fix = frameLayoutGuide.bottomAnchor == view.bottomAnchor
                spring = nil
            case .loose:
                fix = nil
                spring = view.topAnchor == topAnchor
            }

            if let spring = spring {
                bag += signal(for: \.contentSize)[\.height].distinct().atOnce().onValue {
                    spring.constant = $0
                }
            }

            if let fix = fix, adjustForInsets {
                bag += combineLatest(viewHeight, signal(for: \.contentInset)[\.bottom].distinct()).atOnce().onValue { height, bottomInset in
                    fix.constant = bottomInset - height
                }
            }

        case .top:
            precondition(self[insets: insetKey].bottom == 0, "Only one view can be pinned to top")
            bag += viewHeight.atOnce().onValue { height in
                self[insets: insetKey].top = height
            }
            disembedBag += { self[insets: insetKey].top = 0 }

            switch pinning {
            case .spring:
                fix = view.topAnchor == frameLayoutGuide.topAnchor
                fix?.constant = frame.origin.y
                fix?.priority -= 1
                spring = view.bottomAnchor <= topAnchor
            case .fixed:
                fix = view.topAnchor == frameLayoutGuide.topAnchor
                fix?.constant = frame.origin.y
                spring = nil
            case .loose:
                fix = nil
                spring = view.topAnchor == topAnchor
                bag += viewHeight.atOnce().onValue { height in
                    spring?.constant = -height
                }
            }
        }

        bag += subviewsSignal.onValue { _ in
            self.bringSubviewToFront(view)
        }

        constraints += [fix, spring].compactMap { $0 }
        activate(constraints)

        disembedBag += {
            deactivate(constraints)
            view.removeFromSuperview()
        }

        layoutIfNeeded() // To avoid animation bugs when keyboard is being animated immediately at present

        return bag
    }
}

private extension UIScrollView {
    func legacyEmbedPinned(_ view: UIView, edge: PinEdge, minHeight: CGFloat, pinning: Pinning = .fixed, adjustForInsets: Bool = true, disembedBag: DisposeBag? = nil) -> Disposable {
        precondition(minHeight > 0)

        let parent: UIView

        // Handle transitions views that are not custom (our zoom modal). How fragile is this logic?
        if let coord = viewController?.transitionCoordinator, coord.presentationStyle != .custom,
            let containerView: UIView = (coord as? NSObject)?.value(forKey: "containerView") as? UIView,
            self.isDescendant(of: containerView) { // Using value(forKey:) as non-optional coord.containerView might return nil on iOS 9
            parent = containerView
        } else if let superview = self.superview {
            parent = superview
        } else {
            fatalError("The scroll view has to have a superview")
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        let heightConstraint: NSLayoutConstraint
        let viewHeight: ReadSignal<CGFloat>

        if case .fixed = pinning {
            heightConstraint = (view.heightAnchor >= minHeight)
            viewHeight = view.signal(for: \.bounds)[\.size].distinct().map { $0.height }
        } else {
            heightConstraint = (view.heightAnchor == minHeight)
            viewHeight = ReadSignal(minHeight)
        }

        var constraints: [NSLayoutConstraint] = [
            heightConstraint,
            view.widthAnchor == widthAnchor,
            view.leftAnchor == leftAnchor,
            view.rightAnchor == rightAnchor
        ]

        let bag = DisposeBag()
        let insetKey = "embedPinned"

        let fix: NSLayoutConstraint?
        let spring: NSLayoutConstraint?

        switch edge {
        case .bottom:
            // FIXME: enable for iOS 11 if we can remove the re-pin hack
            //precondition(self[insets: insetKey].bottom == 0, "Only one view can be pinned to bottom")
            bag += viewHeight.atOnce().onValue { height in
                self[insets: insetKey].bottom = height
            }

            disembedBag += { self[insets: insetKey].bottom = 0 }

            switch pinning {
            case .spring:
                fix = parent.bottomAnchor == view.bottomAnchor
                spring = view.topAnchor >= topAnchor
                fix?.priority -= 1.0
            case .fixed:
                fix = parent.bottomAnchor == view.bottomAnchor
                spring = nil
            case .loose:
                fix = nil
                spring = view.topAnchor == topAnchor
            }

            if let spring = spring {
                bag += signal(for: \.contentSize)[\.height].distinct().atOnce().onValue {
                    spring.constant = $0
                }
            }

            if let fix = fix, adjustForInsets == true {
                bag += combineLatest(viewHeight, signal(for: \.contentInset)[\.bottom].distinct()).atOnce().onValue { height, bottomInset in
                    fix.constant = bottomInset - height
                }
            }

        case .top:
            // FIXME: enable for iOS 11 if we can remove the re-pin hack
            //precondition(self[insets: insetKey].bottom == 0, "Only one view can be pinned to top")
            bag += viewHeight.atOnce().onValue { height in
                self[insets: insetKey].top = height
            }
            disembedBag += { self[insets: insetKey].top = 0 }

            switch pinning {
            case .spring:
                fix = view.topAnchor == parent.topAnchor
                fix?.constant = frame.origin.y
                fix?.priority -= 1
                spring = view.bottomAnchor <= topAnchor
            case .fixed:
                fix = view.topAnchor == parent.topAnchor
                fix?.constant = frame.origin.y
                spring = nil
            case .loose:
                fix = nil
                spring = view.topAnchor == topAnchor
                bag += viewHeight.atOnce().onValue { height in
                    spring?.constant = -height
                }
            }
        }

        bag += subviewsSignal.onValue { _ in
            self.bringSubviewToFront(view)
        }

        // The parent moved between views when being presented and dismissed etc.
        // This mean we have to re-pin if that happens.
        // FIXME: In iOS 11 we should be able to use contentLayoutGuide instead of parent to setup our constraints and be able to remove this hack.
        bag += combineLatest(parent.subviewsSignal, windowSignal).onValue { [weak parent] _ in
            guard let superView = self.superview, superView != parent else { return }

            let offset = self.contentOffset.y

            bag.dispose()
            deactivate(constraints)
            bag += self.embedPinned(view, edge: edge, minHeight: minHeight, pinning: pinning, adjustForInsets: adjustForInsets, disembedBag: disembedBag)

            self.contentOffset.y = offset
        }

        constraints += [fix, spring].compactMap { $0 }
        activate(constraints)

        disembedBag += {
            deactivate(constraints)
            view.removeFromSuperview()
        }

        layoutIfNeeded() // To avoid animation bugs when keyboard is being animated immediately at present

        return bag
    }
}
