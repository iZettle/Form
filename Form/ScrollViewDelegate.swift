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
