//
//  Reusable.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-09-27.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation
import Flow

/// Conforming types defines how to make a `ReuseType` that can constructed once and configured many times,
/// such as when taking part in in a table or collection view where cells are reused.
public protocol Reusable {
    /// The type to be reused.
    associatedtype ReuseType

    /// Called to produce a type and a closure used to configure the type from an instance of `self`.
    /// The closure returns a `Disposable` for keeping activities alive while being presented.
    ///
    ///     struct Model {
    ///       let name: String
    ///     }
    ///
    ///     extension Model: Reusable {
    ///       static func makeAndConfigure() -> (make: RowView, configure: (Model) -> Disposable) {
    ///         let label = UILabel()
    ///         return (RowView(label), { model in
    ///           label.value = model.name
    ///           return NilDisposer()
    ///         })
    ///       }
    ///     }
    ///
    /// - Note: Only one of `makeAndConfigure()` or `makeAndReconfigure()` should be implemented.
    static func makeAndConfigure() -> (make: ReuseType, configure: (Self) -> Disposable)

    /// Called to produce a type and a closure used to configure it from an preceding and current instance of `self`.
    /// The closure returns a `Disposable` for keeping activities alive while being presented.
    ///
    ///     struct Model {
    ///       let name: String
    ///     }
    ///
    ///     extension Model: Reusable {
    ///       static func makeAndReconfigure() -> (make: RowView, configure: (Model?, Model) -> Disposable) {
    ///         let label = UILabel()
    ///         return (RowView(label), { preceding, current in
    ///           label.value = model.name
    ///           return preceding != current ? label.animateRefresh() : NilDisposer()
    ///         })
    ///       }
    ///     }
    /// - Note: Only one of `makeAndConfigure()` or `makeAndReconfigure()` should be implemented.
    static func makeAndReconfigure() -> (make: ReuseType, reconfigure: (_ preceding: Self?, _ current: Self) -> Disposable)
}

public extension Reusable {
    static func makeAndConfigure() -> (make: ReuseType, configure: (Self) -> Disposable) {
        let (resuseType, reconfigure) = makeAndReconfigure()
        var prevValue: Self? = nil
        return (resuseType, {
            let bag = reconfigure(prevValue, $0)
            prevValue = $0
            return bag
        })
    }

    static func makeAndReconfigure() -> (make: ReuseType, reconfigure: (Self?, Self) -> Disposable) {
        let (resuseType, configure): (make: ReuseType, configure: (Self) -> Disposable) = makeAndConfigure()
        return (resuseType, { configure($1) })
    }

    func reuseTypeAndDisposable() -> (make: ReuseType, disposable: Disposable) {
        let (reuseType, configure) = Self.makeAndConfigure()
        return (reuseType, configure(self))
    }

    func reuseType(bag: DisposeBag) -> ReuseType {
        let (reuseType, disposable) = reuseTypeAndDisposable()
        bag += disposable
        return reuseType
    }

    func reuseType() -> ReuseType {
        return reuseTypeAndDisposable().make
    }
}
