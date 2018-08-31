//
//  MixedReusable.swift
//  Form
//
//  Created by Måns Bernhardt on 2018-08-31.
//  Copyright © 2018 iZettle. All rights reserved.
//

import Foundation
import Flow

/// Helper containter for creating e.g. `Table`s of mixed content.
/// In comparison of using e.g. `Either`, `MixedReusable` will loose type information
/// as it will hold its value as `Any`.
///
///     var mixedTable = Table<(), MixedReusable>(rows: [.init(1), .init("A"), .init("B"), .init(2)])
///
/// - Note: It is often preferable to use e.g. `Either` to not loose types.
public struct MixedReusable {
    private typealias ViewAndReconfigure = (view: UIView, reconfigure: (Any?, Any) -> Disposable)
    private let viewAndReconfigure: () -> ViewAndReconfigure
    let identifier: (Any) -> AnyHashable
    let isSameAs: (Any) -> Bool

    public let value: Any
    public let reuseIdentifier: String

    /// Creates a new instance holding `value`
    ///   - identifier: Closure returning unique identity for a given value
    ///   - isSame: Closure indicating whether two values are equal.
    public init<Value: Reusable>(_ value: Value, identifier: @escaping (Value) -> AnyHashable, isSame: @escaping (Value, Value) -> Bool) where Value.ReuseType: ViewRepresentable {
        self.value = value
        self.identifier = { identifier($0 as! Value) }
        self.isSameAs = { isSame(value, $0 as! Value) }
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

extension MixedReusable {
    /// Creates a new instance holding `value`
    public init<Value: Reusable & Hashable>(_ value: Value) where Value.ReuseType: ViewRepresentable {
        self.init(value, identifier: { $0 }, isSame: ==)
    }
}

extension MixedReusable: Hashable {
    public var hashValue: Int {
        return identifier(value).hashValue
    }

    public static func == (lhs: MixedReusable, rhs: MixedReusable) -> Bool {
        return lhs.reuseIdentifier == rhs.reuseIdentifier && lhs.hashValue == rhs.hashValue && lhs.isSameAs(rhs.value)
    }
}
