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

    /// The reuseIdentifer to be used when `Self` is used with e.g. `UITableView`'s or `UICollectionView`'s
    /// Has a default implementation to return the name of `Self`'s type that should be suitable for most conforming types.
    var reuseIdentifier: String { get }
}

public extension Reusable {
    static func makeAndConfigure() -> (make: ReuseType, configure: (Self) -> Disposable) {
        let (resuseType, reconfigure) = makeAndReconfigure()
        var prevValue: Self?
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

    var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

/// You can use `Either`'s conditional conformance to `Reusable` to create `Table`s of mixed content.
///
///     typealias Row = Either<Int, String>
///     let table = Table<(), Row>(rows: [.left(1), .right("A")]
///
///     typealias Row = Either<Either<Int, String>, Double>
///     let table = Table<(), Row>(rows: [.left(.left(1)), .left(.right("A")), .right(3.14)]]
///
/// - See also: MixedReusable
extension Either: Reusable where Left: Reusable, Right: Reusable, Left.ReuseType: ViewRepresentable, Right.ReuseType: ViewRepresentable {
    public typealias ReuseType = UIView
    private typealias ViewAndReconfigure<T: Reusable> = (make: T.ReuseType, reconfigure: (T?, T) -> Disposable)

    public static func makeAndReconfigure() -> (make: UIView, reconfigure: (Either?, Either) -> Disposable) {
        let row = UIStackView()
        var left: ViewAndReconfigure<Left>!
        var right: ViewAndReconfigure<Right>!

        return (row, { prev, item in
            if left == nil && right == nil {
                switch item {
                case .left:
                    left = Left.makeAndReconfigure()
                    row.orderedViews = [left.make.viewRepresentation]
                case .right:
                    right = Right.makeAndReconfigure()
                    row.orderedViews = [right.make.viewRepresentation]
                }
            }
            switch (prev, item) {
            case (nil, .left(let item)):
                return left.reconfigure(nil, item)
            case (.left(let prev)?, .left(let item)):
                return left.reconfigure(prev, item)
            case (nil, .right(let item)):
                return right.reconfigure(nil, item)
            case (.right(let prev)?, .right(let item)):
                return right.reconfigure(prev, item)
            default:
                assertionFailure("We should never get a mix of left and right for prev and item")
                return NilDisposer()
            }
        })
    }

    public var reuseIdentifier: String {
        switch self {
        case .left(let l): return l.reuseIdentifier
        case .right(let r): return r.reuseIdentifier
        }
    }
}

/// Conforming types specifies what `Reusable` conforming types to use for a section's header and footer.
/// If you need both a header and footer you typically conforms your `Table`'s `Section` type to this protocol.
public protocol HeaderFooterReusable {
    associatedtype Header: Reusable
    associatedtype Footer: Reusable

    /// The value use to render a section's header
    var header: Header { get }

    /// The value use to render a section's footer
    var footer: Footer { get }
}
