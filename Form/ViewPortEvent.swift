//
//  ViewPortEvent.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-12-02.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public struct ViewPortEvent {
    public var viewPort: CGRect
    public var animation: KeyboardAnimation
}

public extension UIView {
    /// Returns the current view port (the window's frame not covered by the status bar or keyboard).
    var viewPort: CGRect {
        return viewPortState.viewPort
    }

    /// Returns a signal for observering view port changes (the window's frame not coverted by the status bar or keyboard).
    func viewPortEventSignal(priority: KeyboardEventPriority = .default) -> Signal<ViewPortEvent> {
        return Signal { callback in
            self.completeOnViewPortEvent(priority: priority) { callback($0); return Future() }
        }
    }

    /// Returns a signal for observering view port changes (the window's frame not coverted by the status bar or keyboard).
    func viewPortSignal(priority: KeyboardEventPriority = .default) -> ReadSignal<CGRect> {
        return viewPortEventSignal(priority: priority).map { $0.viewPort }.readable(capturing: self.viewPort)
    }

    /// Registers a view port event's `callback` where the returned future will hold succeeding keyboard event listeners to receive the event until the future completes.
    func completeOnViewPortEvent(priority: KeyboardEventPriority = .default, callback: @escaping (ViewPortEvent) -> Future<()>) -> Disposable {
        return completeOnKeyboardEvent(priority: priority) { event -> Future<()> in
            switch event {
            case let .willShow(_, animation):
                return callback(ViewPortEvent(viewPort: self.viewPort, animation: animation))
            case let .willHide(animation):
                return callback(ViewPortEvent(viewPort: self.viewPort, animation: animation))
            }
        }
    }
}

private class ViewPortState {
    weak var window: UIWindow? // Not keeping strong reference to the window to avoid UIWindow leaks
    let bag = DisposeBag()
    init(window: UIWindow) {
        self.window = window
        bag += Form.keyboardSignal().onValue { _ in } // Make sure to setup listener so keyboardFrame will be updated
    }

    var viewPort: CGRect {
        var port = window?.bounds ?? .zero
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        port.origin.y = statusBarHeight
        if let frame = keyboardFrame {
            port.size.height = frame.origin.y - statusBarHeight
        }
        return port
    }
}

private var viewPortKey = false
private extension UIView {
    var viewPortState: ViewPortState {
        if let windowState = self.window?.viewPortState {
            setAssociatedValue(windowState, forKey: &viewPortKey)
            return windowState
        }

        let app = UIApplication.shared
        let window = self.window ?? (self as? UIWindow) ?? app.keyWindow ?? app.windows.first!
        return associatedValue(forKey: &viewPortKey, initial: ViewPortState(window: window))
    }
}
