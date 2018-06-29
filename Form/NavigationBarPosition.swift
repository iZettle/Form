//
//  NavigationBarPosition.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-12-09.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Position in the navigation bar
public enum NavigationBarPosition {
    case left, right
}

public extension UINavigationItem {
    /// Sets `items` at `position` optionally animated.
    func setItems(_ items: [UIBarButtonItem], position: NavigationBarPosition, animated: Bool = false) {
        switch position {
        case .left: setLeftBarButtonItems(items, animated: animated)
        case .right: setRightBarButtonItems(items, animated: animated)
        }
    }

    /// Adds `item` the items at `position` optionally animated.
    /// - Returns: `item`
    @discardableResult
    func addItem<Item: UIBarButtonItem>(_ item: Item, position: NavigationBarPosition, animated: Bool = false) -> Item {
        switch position {
        case .left: setItems((leftBarButtonItems ?? []) + [item], position: position, animated: animated)
        case .right: setItems((rightBarButtonItems ?? []) + [item], position: position, animated: animated)
        }
        return item
    }

    /// Sets `item` at `position` optionally animated.
    /// - Returns: `item`
    @discardableResult
    func setItem<Item: UIBarButtonItem>(_ item: Item, position: NavigationBarPosition, animated: Bool = false) -> Item {
        setItems([ item ], position: position, animated: animated)
        return item
    }
}
