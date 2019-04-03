//
//  KeyboardEvent.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-12-02.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public enum KeyboardEvent {
    case willShow(frame: CGRect, animation: KeyboardAnimation)
    case willHide(animation: KeyboardAnimation)
}

public extension KeyboardEvent {
    var animation: KeyboardAnimation {
        switch self {
        case .willShow(_, let animation), .willHide(let animation):
            return animation
        }
    }
}

/// Priority of keyboard event delivery for the same view.
/// When several separate parts participate in adjusting for keyboard events, it is important the adjustments are run in order.
/// To facilitate that, parent views are receivinng keyboard events before their children.
/// But sometimes separate parts participate in adjusting for keyboard events for the same view, such as for scroll views where
/// insets and offset might be adjusted. In those cases a manual priority needs to be provided to break the tie.
/// - Note: A higher value, indicates a higher priority and hence will be sorted to run before a lower priority.
public struct KeyboardEventPriority: RawRepresentable {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension KeyboardEventPriority {
    static let highest = KeyboardEventPriority(rawValue: .max)
    static let lowest = KeyboardEventPriority(rawValue: 0)
    static let `default` = lowest
}

/// Scroll view priorites
public extension KeyboardEventPriority {
    static let contentInsets = KeyboardEventPriority(rawValue: 300)
    static let contentOffset = KeyboardEventPriority(rawValue: 200)
    static let scrollToBottom = KeyboardEventPriority(rawValue: 100)
}

public extension UIView {
    /// Returns a signal for observing keyboard events.
    func keyboardSignal(priority: KeyboardEventPriority = .default) -> Signal<KeyboardEvent> {
        return Signal { callback in
            self.completeOnKeyboardEvent(priority: priority) { callback($0); return Future() }
        }
    }

    /// Registers a keyboard event's `callback` where the returned future will hold succeeding keyboard event listeners to receive the event until the future completes.
    func completeOnKeyboardEvent(priority: KeyboardEventPriority = .default, callback: @escaping (KeyboardEvent) -> Future<()>) -> Disposable {
        if valueCallbacker.isEmpty {
            assert(onKeyboardEventDisposable == nil)
            onKeyboardEventDisposable = Form.keyboardSignal().onValue { event in
                valueCallbacker.callAll(with: event, isOrderedBefore: <)
            }
        }

        let bag = DisposeBag()

        bag += valueCallbacker.addCallback(callback, orderedBy: (self, priority.rawValue))

        bag += {
            if valueCallbacker.isEmpty {
                assert(onKeyboardEventDisposable != nil)
                onKeyboardEventDisposable?.dispose()
                onKeyboardEventDisposable = nil
            }
        }

        return bag
    }
}

func keyboardSignal() -> Signal<KeyboardEvent> {
    return Signal { callback in
        let bag = DisposeBag()

        var prevKeyboardFrame = keyboardFrame
        bag += NotificationCenter.default.signal(forName: UIResponder.keyboardWillShowNotification, object: nil).onValue { notification in
            guard let frame = notification.endFrame, let animation = notification.keyboardAnimation else { return }
            keyboardFrame = frame

            callback(.willShow(frame: frame, animation: frame == prevKeyboardFrame ? .none : animation))
            prevKeyboardFrame = frame
        }

        bag += NotificationCenter.default.signal(forName: UIResponder.keyboardWillHideNotification, object: nil).onValue { notification in
            guard let frame = notification.endFrame, let animation = notification.keyboardAnimation else { return }
            keyboardFrame = nil

            callback(.willHide(animation: frame == prevKeyboardFrame ? .none : animation))
            prevKeyboardFrame = frame
        }

        return bag
    }
}

var keyboardFrame: CGRect?

private extension Notification {
    var keyboardAnimation: KeyboardAnimation? {
        guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let intCurve = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
            else { return nil }

        // UIKeyboardAnimationCurveUserInfoKey might sometimes include values outside of UIViewAnimationCurve
        return KeyboardAnimation(duration: duration, curve: UIView.AnimationCurve(keyboardRawValue: intCurve) ?? .easeInOut)
    }

    var endFrame: CGRect? {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    }
}

private extension UIView.AnimationCurve {
    init?(keyboardRawValue: Int) {
        guard let curve = UIView.AnimationCurve(rawValue: keyboardRawValue) else { return nil }
        let allCases: [UIView.AnimationCurve] = [.easeInOut, .easeInOut, .easeOut, .linear]
        guard allCases.contains(curve) else { return nil }
        self = curve
    }
}

private typealias ViewOrderedValue = (view: UIView, prio: Int)
private func < (_ lhs: ViewOrderedValue, _ rhs: ViewOrderedValue) -> Bool {
    if lhs.view == rhs.view {
        return lhs.prio > rhs.prio
    }
    if lhs.view.isDescendant(of: rhs.view) {
        return false
    }
    if rhs.view.isDescendant(of: lhs.view) {
        return true
    }
    // Compare the closest view to the closest common ancestors, so the compares the branches and not the leaves
    if let commonAncestor = lhs.view.closestCommonAncestor(with: rhs.view),
        let lTopMost = lhs.view.allAncestors(descendantsOf: commonAncestor).map(Array.init)?.last,
        let rTopMost = rhs.view.allAncestors(descendantsOf: commonAncestor).map(Array.init)?.last {
        return Unmanaged.passUnretained(lTopMost).toOpaque() < Unmanaged.passUnretained(rTopMost).toOpaque()
    } else {
        return Unmanaged.passUnretained(lhs.view.rootView).toOpaque() < Unmanaged.passUnretained(rhs.view.rootView).toOpaque()
    }
}

private extension CGRect {
    mutating func adjustForStatusBar() {
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        origin.y = statusBarHeight
        size.height -= statusBarHeight
    }
}

// Sort parent to child first and higher prio to lower prio if views are the same.
private var valueCallbacker = OrderedCallbacker<ViewOrderedValue, KeyboardEvent>()
private var onKeyboardEventDisposable: Disposable?
