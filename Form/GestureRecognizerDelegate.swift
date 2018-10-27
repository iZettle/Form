//
//  GestureRecognizerDelegate.swift
//  Form
//
//  Created by Måns Bernhardt on 2018-10-26.
//  Copyright © 2018 iZettle. All rights reserved.
//

import Flow
import UIKit

public final class GestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    public let shouldBegin = Delegate<(), Bool>()
    public let shouldRecognizeSimultaneouslyWithOtherGestureRecognizer = Delegate<UIGestureRecognizer, Bool>()
    public let shouldRequireFailureOtherGestureRecognizer = Delegate<UIGestureRecognizer, Bool>()
    public let shouldBeRequiredToFailByOtherGestureRecognizer = Delegate<UIGestureRecognizer, Bool>()
    public let shouldReceiveTouch = Delegate<UITouch, Bool>()
    public let shouldReceivePress = Delegate<UIPress, Bool>()

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldBegin.call() ?? true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldRecognizeSimultaneouslyWithOtherGestureRecognizer.call(otherGestureRecognizer) ?? false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldRequireFailureOtherGestureRecognizer.call(otherGestureRecognizer) ?? false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldBeRequiredToFailByOtherGestureRecognizer.call(otherGestureRecognizer) ?? false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return shouldReceiveTouch.call(touch) ?? true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        return shouldReceivePress.call(press) ?? true
    }
}

public extension UIGestureRecognizer {
    func install(_ delegate: UIGestureRecognizerDelegate) -> Disposable {
        self.delegate = delegate
        return Disposer {
            _ = delegate // Hold on to
            self.delegate = nil
        }
    }
}
