//
//  SelectView.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-20.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public final class SelectView: UIView, Selectable, Highlightable {
    private let callbacker = Callbacker<()>()
    private let detectFirstResponder: Bool
    private let backgroundView: UIView?
    private var selectedBackgroundView: UIView?
    private var autoHighlightTime: Date?
    private var bag = DisposeBag()

    public let isSelectedSignal = ReadWriteSignal(false)
    /// highlighted is automatically set and clear according to appropriate touch events.
    public let isHighlightedSignal = ReadWriteSignal(false)

    public init(embeddedView: UIView, withinLayoutArea layoutArea: ViewLayoutArea = .default, backgroundView: UIView? = nil, selectedBackgroundView: UIView? = nil, detectFirstResponder: Bool = true) {
        self.backgroundView = backgroundView
        self.selectedBackgroundView = selectedBackgroundView
        self.detectFirstResponder = detectFirstResponder

        super.init(frame: CGRect.zero)

        _ = backgroundView.map { embedView($0) }
        embedView(embeddedView, withinLayoutArea: layoutArea)
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        bag.dispose()
        if window != nil { // in didMoveToWindow to break any retain cycles when the view is removed
            bag += Flow.combineLatest(isSelectedSignal.atOnce(), isHighlightedSignal.atOnce()).with(weak: self).onValue { _, _, `self` in
                self.updateCurrentState()
            }
        }
    }

    // There must be a more elegant and less hacky way to solve this?
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        guard hasEventListeners else { return view }

        var current: UIView? = view
        while current != nil && current !== self {
            if current is UIControl {
                return view
            }
            current = current?.superview
        }

        return view
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateSelectedForTouches(touches)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateSelectedForTouches(touches)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isSingleAndInside(touches) {
            if callbacker.isEmpty && detectFirstResponder {
                firstPossibleResponder?.becomeFirstResponder()
            } else {
                callbacker.callAll(with: ())
            }
        }

        guard let didHighlightTime = autoHighlightTime else { return }

        guard isSingleAndInside(touches) else {
            updateSelectedForTouches(touches)
            return
        }

        // Make selection to stay around for a while if really fast tap
        let delay = max(0, 0.2 + didHighlightTime.timeIntervalSinceNow)
        Scheduler.main.async(after: delay) {
            self.setHighlighted(false, animated: true)
        }
        autoHighlightTime = nil
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.setHighlighted(false, animated: true)
    }
}

extension SelectView: SignalProvider {
    public var providedSignal: Signal<()> {
        return Signal(callbacker: callbacker)
    }
}

extension SelectView: HasEventListeners {
    public var hasEventListeners: Bool {
        return !callbacker.isEmpty
    }
}

private extension SelectView {
    func setHighlighted(_ val: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.isHighlightedSignal.value = val
            })
        } else {
            self.isHighlightedSignal.value = val
        }
    }

    func updateCurrentState() {
        let highlighted = isHighlightedSignal.value || isSelectedSignal.value

        if let background = selectedBackgroundView, highlighted, background.superview != self { // Lazy embedding
            embedView(background)
            insertSubview(background, at: self.backgroundView == nil ? 0 : 1)
        }

        selectedBackgroundView?.alpha = highlighted  ? 1 : 0

        for var view in allDescendants(ofType: Highlightable.self) {
            view.isHighlighted = highlighted
        }
    }

    func isSingleAndInside(_ touches: Set<UITouch>) -> Bool {
        if let touch = touches.first, touches.count == 1 && bounds.contains(touch.location(in: self)) {
            return true
        } else {
            return false
        }
    }

    func updateSelectedForTouches(_ touches: Set<UITouch>) {
        if isSingleAndInside(touches) && hasEventListeners {
            setHighlighted(true, animated: false)
            autoHighlightTime = Date()
        } else {
            setHighlighted(false, animated: false)
            autoHighlightTime = nil
        }
    }
}
