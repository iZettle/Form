//
//  UIResponders+Utilities.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-09-17.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UIResponder {
    /// Returns the firstResponder if any
    @nonobjc var firstResponder: UIResponder? {
        // Send a message will a nil responder will walk the responder chain an call findFirstResponder on responders that participate in the responder chain. If the participant is not the firstResponder continue with its children if the participant is a view.
        // https://stackoverflow.com/questions/1823317/get-the-current-first-responder-without-using-a-private-api

        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.formFindFirstResponder), to: self, from: nil, for: nil)

        let first = _currentFirstResponder ?? self
        guard !first.isFirstResponder else {
            return first
        }

        let subviews = (first as? UIView)?.subviews ?? (first as? UIViewController).map { [$0.view] } ?? []

        for view in subviews {
            if let firstResponder = view.firstResponder {
                return firstResponder
            }
        }

        return nil
    }

    /// Either calls `becomeFirstResponder()` or `resignFirstResponder()` based on `shouldBecomeFirstResponder`.
    ///
    ///         bag += switch.bindTo(textField.updateFirstResponder)
    func updateFirstResponder(_ shouldBecomeFirstResponder: Bool) {
        if shouldBecomeFirstResponder {
            becomeFirstResponder()
        } else {
            resignFirstResponder()
        }
    }
}

public extension UIControl {
    /// Sets the next responder to become first responder ones `self` ends editing on exit.
    func setNextResponder(_ nextResponder: UIResponder) -> Disposable {
        return signal(for: .editingDidEndOnExit).onValue {
            guard self.isFirstResponder else { return }
            nextResponder.becomeFirstResponder()
        }
    }
}

/// Chain `controls` by setting up the control's next responder using `setNextResponder()`.
/// - Parameters:
///   - shouldLoop: Chain the last control to the first control. Defaults to true.
///   - returnKey: If set, `UIControl`s conforming to `UITextInputTrait` will have their returnKeyType set (if not looping the last one won't be set)
/// - Returns: A disposable that will stop maintaining chain once being disposed.
public func chainResponders(_ controls: [UIControl], shouldLoop: Bool = false, returnKey: UIReturnKeyType? = nil) -> Disposable {
    let bag = DisposeBag()

    let shouldLoop = shouldLoop && controls.count > 1

    var previousControl: UIControl?
    for control in controls {
        bag += previousControl?.setNextResponder(control)
        previousControl = control
    }

    if shouldLoop, let firstControl = controls.first {
        bag += controls.last?.setNextResponder(firstControl)
    }

    if let returnKey = returnKey {
        controls.dropLast(shouldLoop ? 0 : 1).compactMap { $0 as? UITextInputTraits }.filter { $0.returnKeyType != nil }.forEach {
            __setReturnKeyType($0, returnKey)
        }
    }

    return bag
}

/// Chain `controls` by setting up the control's next responder using `setNextResponder()`.
/// - Parameters:
///   - shouldLoop: Chain the last control to the first control. Defaults to true.
///   - returnKey: If set, `UIControl`s conforming to `UITextInputTrait` will have their returnKeyType set (if not looping the last one won't be set)
/// - Returns: A disposable that will stop maintaining chain once being disposed.
public func chainResponders(_ controls: UIControl..., shouldLoop: Bool = false, returnKey: UIReturnKeyType? = nil) -> Disposable {
    return chainResponders(controls, shouldLoop: shouldLoop, returnKey: returnKey)
}

public extension ParentChildRelational where Member: UIView, Self: UIView {
    /// Returns whether `self` of any ancestors are hidden.
    var isSelfOrAnyAncenstorHidden: Bool {
        return isHidden || allAncestors.contains { $0.isHidden }
    }
}

public extension UIView {
    /// Chain all `self`s `UIControl` descendants by setting up the control's next responder using `setNextResponder()`.
    /// The controls are chained in order top left to bottom right.
    /// - Parameters:
    ///   - shouldLoop: Chain the last control to the first control. Defaults to true.
    ///   - returnKey: If set, `UIControl`s conforming to `UITextInputTrait` will have their returnKeyType set (if not looping the last one won't be set)
    /// - Returns: A disposable that will stop maintaining chaining once being disposed.
    /// - Note: Changes in descentants and/or their visiblity will update the chain.
    func chainAllControlResponders(shouldLoop: Bool = false, returnKey: UIReturnKeyType? = nil) -> Disposable {
        let bag = DisposeBag()

        let treeChangeBag = DisposeBag()
        bag += treeChangeBag

        // Listen to any cahnge in the view tree
        bag += self.allDescendantsSignal.map { $0.compactMap { $0 as? UIControl }.filter { $0.canBecomeFirstResponder } }.atOnce().onValue { controls in
            treeChangeBag.dispose()

            let chainingBag = DisposeBag()
            treeChangeBag += chainingBag

            // Observing if a view becomes hidden or visible
            let viewsToObserve = Set([self] + controls.flatMap { $0.allAncestors(descendantsOf: self).map(Array.init) ?? [] })
            treeChangeBag += merge(viewsToObserve.reduce([]) { $0 + [$1.signal(for: \.isHidden)] }).atOnce().onValue { _ in
                chainingBag.dispose()
                let chainableControls = self.chainableControls.sorted(by: self.topLeftToBottomRightSort)
                chainingBag += chainResponders(chainableControls, shouldLoop: shouldLoop, returnKey: returnKey)
            }
        }

        return bag
    }

    /// Returns the first found descendant the can become first responder and is not hidden or have any ancesters that are hidden.
    var firstPossibleResponder: UIView? {
        return allDescendants.first { $0.canBecomeFirstResponder && !$0.isSelfOrAnyAncenstorHidden }
    }
}

internal extension UIResponder {
    @objc func formFindFirstResponder(sender: AnyObject) {
        _currentFirstResponder = self
    }
}

private var _currentFirstResponder: UIResponder?

private extension UIView {
    var chainableControls: [UIControl] {
        return allDescendants(ofType: UIControl.self).filter { $0.canBecomeFirstResponder && !$0.isSelfOrAnyAncenstorHidden }
    }
}

private extension UICoordinateSpace {
    func topLeftToBottomRightSort(first: UICoordinateSpace, second: UICoordinateSpace) -> Bool {
        return first.isPositionedBefore(second)
    }

    func isPositionedBefore(_ second: UICoordinateSpace) -> Bool {
        let firstFrame = bounds
        let secondFrame = second.convert(second.bounds, to: self)
        if firstFrame.maxY <= secondFrame.minY { return true }
        if firstFrame.minY < secondFrame.maxY { return firstFrame.minX < secondFrame.minX }
        return false
    }
}
