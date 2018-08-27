//
// Created by Niil Öhlin on 2018-07-12.
// Copyright (c) 2018 iZettle. All rights reserved.
//
import Foundation
import Flow

public class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
    private let didEndDeceleratingCallbacker = Callbacker<UIScrollView>()
    private let didScrollCallbacker = Callbacker<UIScrollView>()
    private let willBeginDeceleratingCallbacker = Callbacker<UIScrollView>()
    private let willBeginDraggingCallbacker = Callbacker<UIScrollView>()
    private let didZoomCallbacker = Callbacker<UIScrollView>()

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        didZoomCallbacker.callAll(with: scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willBeginDraggingCallbacker.callAll(with: scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndDeceleratingCallbacker.callAll(with: scrollView)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollCallbacker.callAll(with: scrollView)
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        willBeginDeceleratingCallbacker.callAll(with: scrollView)
    }
}

public extension ScrollViewDelegate {
    var didEndDecelerating: Signal<UIScrollView> {
        return Signal(callbacker: didEndDeceleratingCallbacker)
    }

    var willBeginDecelerating: Signal<UIScrollView> {
        return Signal(callbacker: willBeginDeceleratingCallbacker)
    }

    var didScroll: Signal<UIScrollView> {
        return Signal(callbacker: didScrollCallbacker)
    }

    var didZoom: Signal<UIScrollView> {
        return Signal(callbacker: didZoomCallbacker)
    }

    var willBeginDragging: Signal<UIScrollView> {
        return Signal(callbacker: willBeginDraggingCallbacker)
    }
}
