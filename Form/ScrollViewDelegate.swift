//
// Created by Niil Öhlin on 2018-07-12.
// Copyright (c) 2018 iZettle. All rights reserved.
//

import Foundation
import Flow

public class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
    private let didEndDeceleratingCallbacker = Callbacker<()>()
    private let didScrollCallbacker = Callbacker<()>()
    private let willBeginDeceleratingCallbacker = Callbacker<()>()
    private let willBeginDraggingCallbacker = Callbacker<()>()
    private let didZoomCallbacker = Callbacker<()>()
    private let willEndDraggingCallbacker = Callbacker<(velocity: CGPoint, targetContentOffset: CGPoint?)>()
    private let didEndDraggingCallbacker = Callbacker<Bool>()
    private let didEndScrollingAnimationCallbacker = Callbacker<()>()
    private let willBeginZoomingCallbacker = Callbacker<UIView?>()
    private let didEndZoomingCallbacker = Callbacker<(view: UIView?, scale: CGFloat)>()
    private let didScrollToTopCallbacker = Callbacker<()>()
    private let didChangeAdjustedContentInsetCallbacker = Callbacker<()>()

    public let targetContentOffsetFromVelocity = Delegate<CGPoint, CGPoint?>()
    public let shouldScrollToTop = Delegate<(), Bool>()
    public let viewForZooming = Delegate<(), UIView?>()

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        didZoomCallbacker.callAll()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willBeginDraggingCallbacker.callAll()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndDeceleratingCallbacker.callAll()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollCallbacker.callAll()
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        willBeginDeceleratingCallbacker.callAll()
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let target = targetContentOffsetFromVelocity.call(velocity), let point = target {
            targetContentOffset.pointee = point
            willEndDraggingCallbacker.callAll(with: (velocity, point))
        } else {
            let point: CGPoint = targetContentOffset.pointee
            willEndDraggingCallbacker.callAll(with: (velocity, point))
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        didEndDraggingCallbacker.callAll(with: decelerate)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didEndScrollingAnimationCallbacker.callAll()
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return viewForZooming.call().flatMap { $0 }
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        willBeginZoomingCallbacker.callAll(with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        didEndZoomingCallbacker.callAll(with: (view: view, scale: scale))
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return shouldScrollToTop.call() ?? true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        didScrollToTopCallbacker.callAll()
    }

    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        didChangeAdjustedContentInsetCallbacker.callAll()
    }
}

public extension ScrollViewDelegate {
    var didEndDecelerating: Signal<()> {
        return Signal(callbacker: didEndDeceleratingCallbacker)
    }

    var willBeginDecelerating: Signal<()> {
        return Signal(callbacker: willBeginDeceleratingCallbacker)
    }

    var didScroll: Signal<()> {
        return Signal(callbacker: didScrollCallbacker)
    }

    var didZoom: Signal<()> {
        return Signal(callbacker: didZoomCallbacker)
    }

    var willBeginDragging: Signal<()> {
        return Signal(callbacker: willBeginDraggingCallbacker)
    }

    @available(*, deprecated, renamed: "willEndDragging")
    var willEndDraggingWithVelocity: Signal<CGPoint> {
        return willEndDragging.map { $0.velocity }
    }

    var willEndDragging: Signal<(velocity: CGPoint, targetContentOffset: CGPoint?)> {
        return Signal(callbacker: willEndDraggingCallbacker)
    }

    var didEndDraggingDecelerate: Signal<Bool> {
        return Signal(callbacker: didEndDraggingCallbacker)
    }

    var didEndScrollingAnimation: Signal<()> {
        return Signal(callbacker: didEndScrollingAnimationCallbacker)
    }

    var willBeginZooming: Signal<UIView?> {
        return Signal(callbacker: willBeginZoomingCallbacker)
    }

    var didEndZooming: Signal<(view: UIView?, scale: CGFloat)> {
        return Signal(callbacker: didEndZoomingCallbacker)
    }

    var didScrollToTop: Signal<()> {
        return Signal(callbacker: didScrollToTopCallbacker)
    }

    var didChangeAdjustedContentInset: Signal<()> {
        return Signal(callbacker: didChangeAdjustedContentInsetCallbacker)
    }
}

public extension UIScrollView {
    func install(_ delegate: UIScrollViewDelegate) -> Disposable {
        self.delegate = delegate
        return Disposer {
            _ = delegate // Hold on to
            self.delegate = nil
        }
    }
}
