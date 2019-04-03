//
//  UIScrollView+Keyboard.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-12-01.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UIScrollView {
    /// Will dynamically adjust the content insets of `self` to make room for the keyboard.
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func adjustInsetsForKeyboard() -> Disposable {
        var initialBottomInset: CGFloat?

        func adjust(viewPort: CGRect) {
            let frame = self.absoluteFrame
            let clippedFrame = frame.intersection(viewPort)

            if initialBottomInset == nil {
                initialBottomInset = self.contentInset.bottom
            }

            var insets = UIEdgeInsets.zero
            insets.bottom = max(initialBottomInset ?? insets.bottom, frame.maxY - clippedFrame.maxY)

            let originalInsets = self.contentInset
            self[insets: "adjustInsetsForKeyboard"] = insets
            if originalInsets != self.contentInset {
                self.layoutIfNeeded()
            }
        }

        let bag = DisposeBag()

        bag += viewPortSignal(priority: .contentInsets).atOnce().onValue(adjust)

        // When the vc has transitioned to a new parent VC we need to update the view port
        // The view hierarchy changes when a VC is pushed (a _UIParallaxDimmingView is inserted and the absoluteFrame changes)
        self.viewController?.transitionCoordinator?.animate(alongsideTransition: nil) { _ in
            adjust(viewPort: self.viewPort)
        }

        // When zoom modal is adjusted navigation controller sub controller is not adjusted at once, and inset be calculated on incorrect frame. This will adjust for this when later on the view is updated.
        bag += signal(for: \.frame).onValue { _ in adjust(viewPort: self.viewPort) }

        return bag
    }
}

public extension UIScrollView {
    /// Will dynamically adjust the content offset of `self` to reveal first responders.
    /// Parameter adjustInsets: Function to adjust the frame of the first responder view used to calculate the content offset. Defaults to `alignToRow`.
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func scrollToRevealFirstResponder(_ adjustInsets: @escaping (UIView) -> UIEdgeInsets = alignToRow) -> Disposable {
        let bag = DisposeBag()
        var lastResponder = firstResponder

        adjustContentOffset(adjustInsets)

        bag += keyboardSignal(priority: .contentOffset).onValue { event -> Void in
            lastResponder = self.firstResponder
            guard case let .willShow(_, animation) = event else { return }
            animation.animate { self.adjustContentOffset(adjustInsets) }
        }

        bag += NotificationCenter.default.signal(forName: UITextField.textDidBeginEditingNotification).onValue { _ in
            DispatchQueue.main.async { // Make sure to run after onKeyboardEvent above.
                defer { lastResponder = self.firstResponder }
                guard self.firstResponder != lastResponder else { return }
                UIView.animate(withDuration: 0.3) { self.adjustContentOffset(adjustInsets) }
            }
        }

        return bag
    }

    /// Will dynamically update `isScrollEnabled` to be disabled when content fits.
    /// - Returns: A disposable that will stop adjustments when being disposed.
    @available(*, deprecated, message: "use `alwaysBounceVertical = false` instead")
    func disableScrollingIfContentFits() -> Disposable {
        return combineLatest(signal(for: \.frame), signal(for: \.contentSize), signal(for: \.contentInset)).map { frame, contentSize, contentInset in
            (frame.inset(by: contentInset).size, contentSize)
        }.bindTo { (insetSize: CGSize, contentSize: CGSize) in
            self.isScrollEnabled = insetSize.width < contentSize.width || insetSize.height < contentSize.height
        }
    }

    /// Updates the content offset to scroll to top.
    func scrollToTop(animated: Bool) {
        var offset = contentOffset
        offset.y = contentInset.top
        setContentOffset(offset, animated: animated)
    }

    /// Updates the content offset to scroll to bottom.
    func scrollToBottom(animated: Bool) {
        var offset = contentOffset
        offset.y = max(-contentInset.top, contentSize.height - bounds.size.height + contentInset.bottom)
        setContentOffset(offset, animated: animated)
    }

    /// Will scroll to bottom if `responder` becomes first responder.
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func scrollToBottom(for responder: UIResponder) -> Disposable {
        let bag = DisposeBag()
        var lastResponder = firstResponder

        bag += keyboardSignal(priority: .scrollToBottom).onValue { event -> Void in
            lastResponder = self.firstResponder
            guard case let .willShow(_, animation) = event, self.firstResponder == responder else { return }
            animation.animate {
                self.scrollToBottom(animated: false)
            }
        }

        bag += NotificationCenter.default.signal(forName: UITextField.textDidBeginEditingNotification).onValue { _ in
            DispatchQueue.main.async { // Make sure to run after onKeyboardEvent above.
                defer { lastResponder = self.firstResponder }
                guard self.firstResponder == responder && self.firstResponder != lastResponder else { return }
                self.scrollToBottom(animated: true)
            }
        }

        return bag
    }
}

public extension UIScrollView {
    /// Allow multiple unrelated users to affect the content insets (such as keyboard avoidance and view pinning)
    subscript(insets key: String) -> UIEdgeInsets {
        get { return contentInsets[key] ?? .zero }
        set {
            contentInsets[key] = newValue
            let inset = contentInsets.values.reduce(.zero, +)
            contentInset = inset
            scrollIndicatorInsets = inset
        }
    }
}

/// Will try to find the containing `SelectView` (row) of `view` and return the insets relative `view` to construct the frame of `SelectView`.
/// - Note: Used by `scrollToRevealFirstResponder` to scroll to row frame instead of potentially smaller view frame (such as when using a text field in a row).
public func alignToRow(_ view: UIView) -> UIEdgeInsets {
    guard let rowView = view.firstAncestor(ofType: SelectView.self) else { return UIEdgeInsets.zero }
    let rect = rowView.convert(view.bounds, from: view)

    return UIEdgeInsets(top: -rect.minY, left: -rect.minX, bottom: -(rowView.frame.height-rect.maxY), right: -(rowView.frame.width-rect.maxX))
}

private extension UIScrollView {
    var contentInsets: [String: UIEdgeInsets] {
        get { return associatedValue(forKey: &contentInsetsKey, initial: [:]) }
        set {
            setAssociatedValue(newValue, forKey: &contentInsetsKey)
            let insets = newValue.values.reduce(.zero, +)
            contentInset = insets
            scrollIndicatorInsets = insets
        }
    }

    func adjustContentOffset(_ adjustInsets: (UIView) -> UIEdgeInsets) {
        guard let firstResponder = firstResponder as? UIView else { return }

        let viewRect = frame.inset(by: contentInset)
        let firstBounds = firstResponder.bounds.inset(by: adjustInsets(firstResponder))
        let firstFrame = convert(firstBounds, from: firstResponder)

        var portRect = viewRect
        portRect.origin.y += contentOffset.y

        // Don't let horizontal values affect contains below.
        portRect.origin.x -= 1000
        portRect.size.width += 2000

        guard !portRect.contains(firstFrame) else { return }

        var offset = contentOffset
        let bottom = firstFrame.maxY - viewRect.size.height - contentInset.top
        let marginY = layoutMargins.top + contentInset.top

        if bottom > -max(marginY, firstFrame.height) {
            offset.y = bottom
        } else {
            offset.y = -marginY
        }

        setContentOffset(offset, animated: false)
    }
}

private var contentInsetsKey = false
