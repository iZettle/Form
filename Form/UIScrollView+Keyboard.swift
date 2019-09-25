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

        self.adjustContentOffsetToRevealFirstResponder(adjustInsets)

        bag += keyboardSignal(priority: .contentOffset).onValue { event -> Void in
            lastResponder = self.firstResponder
            guard case let .willShow(_, animation) = event else { return }
            animation.animate { self.adjustContentOffsetToRevealFirstResponder(adjustInsets) }
        }

        bag += NotificationCenter.default.signal(forName: UITextField.textDidBeginEditingNotification).onValue { _ in
            DispatchQueue.main.async { // Make sure to run after onKeyboardEvent above.
                defer { lastResponder = self.firstResponder }
                guard self.firstResponder != lastResponder else { return }
                UIView.animate(withDuration: 0.3) { self.adjustContentOffsetToRevealFirstResponder(adjustInsets) }
            }
        }

        return bag
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

    func adjustContentOffsetToRevealFirstResponder(_ adjustInsets: (_ firstResponder: UIView) -> UIEdgeInsets) {
        if let targetVisibleRect = self.targetVisibleRectToRevealFirstResponder(adjustInsets) {
            self.scrollRectToVisible(targetVisibleRect, animated: false)
        }
    }

    func targetVisibleRectToRevealFirstResponder(_ adjustInsets: (_ firstResponder: UIView) -> UIEdgeInsets) -> CGRect? {
        guard let frameToFocus = self.firstResponderAdjustedFrame(adjustInsets: adjustInsets) else { return nil }

        let verticalFocusPosition = ScrollViewVerticalContext(
            visibleRectHeight: self.bounds.height,
            visibleRectOffsetY: self.contentOffset.y,
            visibleRectInsetTop: self.contentInset.top,
            visibleRectInsetBottom: self.contentInset.bottom
        ).targetFocusPosition(for: frameToFocus)

        return verticalFocusPosition.flatMap { CGRect(x: 0, y: $0, width: 1, height: 1) }
    }

    func firstResponderAdjustedFrame(adjustInsets: (_ firstResponder: UIView) -> UIEdgeInsets) -> CGRect? {
        guard let firstResponder = firstResponder as? UIView else { return nil }
        let insetAdjustment = adjustInsets(firstResponder)
        let frameToFocus = firstResponder.frame.inset(by: insetAdjustment)
        return self.convert(frameToFocus, from: firstResponder)
    }
}

// Internal helper to move scroll view vertical position calculations outside of the view so that we can test them
struct ScrollViewVerticalContext {
    let visibleRectHeight: CGFloat
    let visibleRectOffsetY: CGFloat
    let visibleRectInsetTop: CGFloat
    let visibleRectInsetBottom: CGFloat

    // Calculates the vertical position of the area that needs to become visible for the given frame to be focused.
    // It calculates the smallest movement needed based on the relative position on the `frameToFocus`.
    // Nil if the frame is already focused.
    func targetFocusPosition(for frameToFocus: CGRect) -> CGFloat? {
        let visibleRectMinY = visibleRectOffsetY - visibleRectInsetTop
        let visibleRectMaxY = visibleRectMinY + visibleRectHeight - visibleRectInsetBottom

        let isBelowTop = frameToFocus.minY >= visibleRectMinY
        let isAboveBottom = frameToFocus.maxY <= visibleRectMaxY
        let isFirstResponderVisible = isBelowTop && isAboveBottom

        guard !isFirstResponderVisible else { return nil }

        if !isBelowTop {
            return max(0, frameToFocus.minY)
        } else {
            return max(0, frameToFocus.maxY)
        }
    }
}

private var contentInsetsKey = false
