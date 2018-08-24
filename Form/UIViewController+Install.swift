//
//  UIViewController+Install.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-09-28.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Options to customize view controller view installations.
public struct InstallOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension InstallOptions {
    /// Whether to call `UIScrollView.adjustInsetsForKeyboard()`.
    static let adjustInsetsForKeyboard = InstallOptions(rawValue: 1<<0)

    /// Whether to call `scrollToRevealFirstResponder()`.
    static let scrollToRevealFirstResponder = InstallOptions(rawValue: 1<<1)

    /// [.adjustInsetsForKeyboard, .scrollToRevealFirstResponder]
    static let adjustForKeyboard: InstallOptions = [.adjustInsetsForKeyboard, .scrollToRevealFirstResponder]

    /// Whether to call `disableScrollingIfContentFits()`.
    static let disableScrollingIfContentFits = InstallOptions(rawValue: 1<<2)

    /// Whether to call `embedWithSpacingBetween()` if more then one view.
    static let insertSpacingToFillUpHeight = InstallOptions(rawValue: 1<<3)

    /// [.adjustForKeyboard, .insertSpacingToFillUpHeight]
    static let defaults: InstallOptions = [.adjustForKeyboard, .insertSpacingToFillUpHeight]
}

public extension UIViewController {
    /// Will embed orderedViews into a `scrollView` and set `self.view` to that scroll view.
    /// Parameters:
    ///   - orderedViews: Views to add in order from top to bottom into `scrollView`.
    ///   - options: Installation options.
    ///   - scrollView: The scrollView to install on `self` with `orderdedView` added to it.
    ///   - onInstall: Called when the the scroll view is added to the view hierarchy (added to a window)
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func install(_ orderedViews: [UIView], options: InstallOptions = .defaults, scrollView: UIScrollView = .default, onInstall: ((UIScrollView) -> Void)? = nil) -> Disposable {
        precondition(!orderedViews.isEmpty, "orderedViews must contain at least one view")

        let bag = DisposeBag()

        if options.contains(.insertSpacingToFillUpHeight) && orderedViews.count > 1 {
            bag += scrollView.embedWithSpacingBetween(orderedViews)
        } else {
            let view = orderedViews.count == 1 ? orderedViews[0] : UIStackView(rows: orderedViews, spacing: 0)
            scrollView.embedView(view, scrollAxis: .vertical)
        }

        bag += installScrollView(scrollView, options: options, onInstall: onInstall)

        return bag
    }

    /// Will embed orderedViews into a `scrollView` and set `self.view` to that scroll view.
    /// Parameters:
    ///   - orderedViews: Views to add in order from top to bottom into `scrollView`.
    ///   - options: Installation options.
    ///   - scrollView: The scrollView to install on `self` with `orderdedView` added to it.
    ///   - onInstall: Called when the the scroll view is added to the view hierarchy (added to window)
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func install(_ orderedViews: UIView..., options: InstallOptions = .defaults, scrollView: UIScrollView = .default, onInstall: ((UIScrollView) -> Void)? = nil) -> Disposable {
        return install(orderedViews, options: options, scrollView: scrollView, onInstall: onInstall)
    }

    /// Will set `self.view` to `tableView`.
    ///   - options: Installation options.
    ///   - onInstall: Called when the the table view is added to the view hierarchy (added to a window)
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func install(_ tableView: UITableView, options: InstallOptions = .defaults, onInstall: ((UITableView) -> Void)? = nil) -> Disposable {
        return installScrollView(tableView, options: options, onInstall: onInstall)
    }

    /// Will set `self.view` to `collectionView`.
    ///   - options: Installation options.
    ///   - onInstall: Called when the the table view is added to the view hierarchy (added to a window)
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func install(_ collectionView: UICollectionView, options: InstallOptions = .defaults, onInstall: ((UICollectionView) -> Void)? = nil) -> Disposable {
        return installScrollView(collectionView, options: options, onInstall: onInstall)
    }

    /// Will set `self.view` to `tableKit.view`.
    ///   - tableKit: The table kit of which `view` will be installed.
    ///   - options: Installation options.
    ///   - onInstall: Called when the the table view is added to the view hierarchy (added to a window)
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func install<Section, Row>(_ tableKit: TableKit<Section, Row>, options: InstallOptions = .defaults, onInstall: ((UITableView) -> Void)? = nil) -> Disposable {
        return install(tableKit.view, options: options, onInstall: onInstall)
    }

    /// Will set `self.view` to `collectionKit.view`.
    ///   - collectionKit: The collection kit of which `view` will be installed.
    ///   - options: Installation options.
    ///   - onInstall: Called when the the collection view is added to the view hierarchy (added to a window)
    /// - Returns: A disposable that will stop adjustments when being disposed.
    func install<Section, Row>(_ collectionKit: CollectionKit<Section, Row>, options: InstallOptions = .defaults, onInstall: ((UICollectionView) -> Void)? = nil) -> Disposable {
        return install(collectionKit.view, options: options, onInstall: onInstall)
    }
}

private extension UIViewController {
    func installScrollView<T: UIScrollView>(_ scrollView: T, options: InstallOptions, onInstall: ((T) -> Void)?) -> Disposable {
        let bag = DisposeBag()

        scrollView.alwaysBounceVertical = !options.contains(.disableScrollingIfContentFits)

        bag += combineLatest(scrollView.didMoveToWindowSignal, scrollView.didLayoutSignal).onFirstValue { _ in
            if self.automaticallyAdjustsScrollViewInsets {
                scrollView[insets: "automaticallyAdjustsScrollViewInsets"] = scrollView.contentInset
            }

            if options.contains(.adjustInsetsForKeyboard) {
                bag += scrollView.adjustInsetsForKeyboard()
            }

            if options.contains(.scrollToRevealFirstResponder) {
                bag += scrollView.scrollToRevealFirstResponder()
            }

            onInstall?(scrollView)
        }

        self.view = scrollView

        return bag
    }
}
