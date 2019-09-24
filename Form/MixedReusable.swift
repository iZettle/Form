//
//  MixedReusable.swift
//  Form
//
//  Created by Måns Bernhardt on 2018-08-31.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Helper containter for creating e.g. `Table`s of mixed content.
/// In comparison of using e.g. `Either`, `MixedReusable` will lose type information
/// as it will hold its value as `Any`.
///
///     var mixedTable = Table<(), MixedReusable>(rows: [.init(1), .init("A"), .init("B"), .init(2)])
///
/// - Note: It is often preferable to use e.g. `Either` to not loose types.
public struct MixedReusable {
    private typealias ViewAndReconfigure = (view: UIView, reconfigure: (Any?, Any) -> Disposable)
    private let viewAndReconfigure: () -> ViewAndReconfigure
    let identifier: (Any) -> AnyHashable
    let needsUpdate: (Any) -> Bool

    public let value: Any
    public let reuseIdentifier: String

    /// Creates a new instance holding `value`
    ///   - identifier: Closure returning unique identity for a given value
    ///   - isSame: Closure indicating whether two values are equal.
    ///   - identifier: Closure returning unique identity for a given value
    ///   - rowNeedsUpdate: Closure indicating whether two values with equal identifiers have any updates.
    ///           Defaults to true. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    public init<Value: Reusable>(_ value: Value, identifier: @escaping (Value) -> AnyHashable, needsUpdate: @escaping (Value, Value) -> Bool = { _, _ in true }) where Value.ReuseType: ViewRepresentable {
        self.value = value
        self.identifier = { identifier($0 as! Value) }
        self.needsUpdate = { needsUpdate(value, $0 as! Value) }
        self.reuseIdentifier = String(describing: type(of: Value.self))
        self.viewAndReconfigure = {
            let (reuseType, reconfigure) = Value.makeAndReconfigure()
            return (reuseType.viewRepresentation, { reconfigure($0 as! Value?, $1 as! Value) })
        }
    }
}

extension MixedReusable: Reusable {
    public static func makeAndReconfigure() -> (make: UIView, reconfigure: (MixedReusable?, MixedReusable) -> Disposable) {
        let row = UIStackView()
        var viewAndReconfigure: ViewAndReconfigure?
        return (row, { prev, mixed in
            if viewAndReconfigure == nil {
                viewAndReconfigure = mixed.viewAndReconfigure()
                row.orderedViews = [viewAndReconfigure!.view]
            }
            return viewAndReconfigure!.reconfigure(prev?.value, mixed.value)
        })
    }
}

public extension MixedReusable {
    /// Creates a new instance holding `value`
    ///   - identifier: Closure returning unique identity for a given value
    init<Value: Reusable & Equatable>(_ value: Value, identifier: @escaping (Value) -> AnyHashable) where Value.ReuseType: ViewRepresentable {
        self.init(value, identifier: identifier, needsUpdate: !=)
    }

    /// Creates a new instance holding `value`
    init<Value: Reusable & Hashable>(_ value: Value) where Value.ReuseType: ViewRepresentable {
        self.init(value, identifier: { $0 }, needsUpdate: !=)
    }
}

public extension TableAnimatable where Row == MixedReusable, Section == EmptySection {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    func set(_ table: Table, animation: Animation = Self.defaultAnimation) {
        set(table, animation: animation, rowIdentifier: rowIdentifier, rowNeedsUpdate: rowNeedsUpdate)
    }
}

public extension TableAnimatable where Row == MixedReusable, Section: Hashable {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    func set(_ table: Table, animation: Animation = Self.defaultAnimation) {
        set(table, animation: animation, rowIdentifier: rowIdentifier, rowNeedsUpdate: rowNeedsUpdate)
    }
}

public extension TableAnimatable where Row == MixedReusable, Section: AnyObject {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    func set(_ table: Table, animation: Animation = Self.defaultAnimation) {
        set(table, animation: animation, rowIdentifier: rowIdentifier, rowNeedsUpdate: rowNeedsUpdate)
    }
}

private func rowIdentifier(_ row: MixedReusable) -> AnyHashable {
    return row.identifier(row.value).hashValue
}

private func rowNeedsUpdate(_ lhs: MixedReusable, _ rhs: MixedReusable) -> Bool {
    return lhs.reuseIdentifier == rhs.reuseIdentifier && lhs.needsUpdate(rhs.value)
}
