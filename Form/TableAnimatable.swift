//
//  TableAnimatable.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-10-11.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

public protocol TableAnimatable {
    associatedtype Section
    associatedtype Row
    associatedtype Animation

    typealias Table = Form.Table<Section, Row>

    static var defaultAnimation: Animation { get }

    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - sectionIdentifier: Closure returning unique identity for a given section
    ///   - rowIdentifier: Closure returning unique identity for a given row
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to true. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    func set<SectionIdentifier: Hashable, RowIdentifier: Hashable>(_ table: Table,
                                                                   animation: Animation,
                                                                   sectionIdentifier: (Section) -> SectionIdentifier,
                                                                   rowIdentifier: (Row) -> RowIdentifier,
                                                                   rowNeedsUpdate: ((Row, Row) -> Bool)?)
}

public extension TableAnimatable where Row: Equatable {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - sectionIdentifier: Closure returning unique identity for a given section
    ///   - rowIdentifier: Closure returning unique identity for a given row
    func set<SectionIdentifier: Hashable, RowIdentifier: Hashable>(_ table: Table,
                                                                   animation: Animation = Self.defaultAnimation,
                                                                   sectionIdentifier: (Section) -> SectionIdentifier,
                                                                   rowIdentifier: (Row) -> RowIdentifier) {
        set(table, animation: animation, sectionIdentifier: sectionIdentifier, rowIdentifier: rowIdentifier, rowNeedsUpdate: !=)
    }
}

public extension TableAnimatable where Section == EmptySection {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowIdentifier: Closure returning unique identity for a given row
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to nil. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    func set<RowIdentifier: Hashable>(_ table: Table,
                                      animation: Animation = Self.defaultAnimation,
                                      rowIdentifier: (Row) -> RowIdentifier,
                                      rowNeedsUpdate: ((Row, Row) -> Bool)? = nil) {
        set(table, animation: animation, sectionIdentifier: { _ in 0 }, rowIdentifier: rowIdentifier, rowNeedsUpdate: rowNeedsUpdate)
    }
}

public extension TableAnimatable where Section == EmptySection, Row: Equatable {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowIdentifier: Closure returning unique identity for a given row
    func set<RowIdentifier: Hashable>(_ table: Table, animation: Animation = Self.defaultAnimation, rowIdentifier: (Row) -> RowIdentifier) {
        set(table, animation: animation, sectionIdentifier: { _ in 0 }, rowIdentifier: rowIdentifier)
    }
}

public extension TableAnimatable where Section == EmptySection, Row: Hashable {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    func set(_ table: Table, animation: Animation = Self.defaultAnimation) {
        set(table, animation: animation, rowIdentifier: { $0 })
    }
}

public extension TableAnimatable where Section == EmptySection, Row: AnyObject {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    func set(_ table: Table, animation: Animation = Self.defaultAnimation) {
        set(table, animation: animation, rowIdentifier: ObjectIdentifier.init)
    }
}

public extension TableAnimatable where Section: Hashable {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowIdentifier: Closure returning unique identity for a given row
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to nil. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    func set<RowIdentifier: Hashable>(_ table: Table, animation: Animation = Self.defaultAnimation, rowIdentifier: (Row) -> RowIdentifier, rowNeedsUpdate: ((Row, Row) -> Bool)? = nil) {
        set(table, animation: animation, sectionIdentifier: { $0 }, rowIdentifier: rowIdentifier, rowNeedsUpdate: rowNeedsUpdate)
    }
}

public extension TableAnimatable where Section: AnyObject {
    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowIdentifier: Closure returning unique identity for a given row
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to nil. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    func set<RowIdentifier: Hashable>(_ table: Table, animation: Animation = Self.defaultAnimation, rowIdentifier: (Row) -> RowIdentifier, rowNeedsUpdate: ((Row, Row) -> Bool)? = nil) {
        set(table, animation: animation, sectionIdentifier: ObjectIdentifier.init, rowIdentifier: rowIdentifier, rowNeedsUpdate: rowNeedsUpdate)
    }
}

public extension TableAnimatable where Section: Hashable, Row: Equatable {
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowIdentifier: Closure returning unique identity for a given row
    func set<RowIdentifier: Hashable>(_ table: Table, animation: Animation = Self.defaultAnimation, rowIdentifier: (Row) -> RowIdentifier) {
        set(table, animation: animation, rowIdentifier: rowIdentifier, rowNeedsUpdate: !=)
    }
}

public extension TableAnimatable where Section: Hashable, Row: Hashable {
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    func set(_ table: Table, animation: Animation = Self.defaultAnimation) {
        set(table, animation: animation, rowIdentifier: { $0 })
    }
}

public extension TableAnimatable where Section: Hashable, Row: AnyObject {
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to nil. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    func set(_ table: Table, animation: Animation = Self.defaultAnimation, rowNeedsUpdate: ((Row, Row) -> Bool)? = nil) {
        set(table, animation: animation, rowIdentifier: ObjectIdentifier.init, rowNeedsUpdate: rowNeedsUpdate)
    }
}

public extension TableAnimatable where Section: AnyObject, Row: Hashable {
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to nil. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    func set(_ table: Table, animation: Animation = Self.defaultAnimation, rowNeedsUpdate: ((Row, Row) -> Bool)? = nil) {
        set(table, animation: animation, rowIdentifier: { $0 }, rowNeedsUpdate: rowNeedsUpdate)
    }
}

public extension TableAnimatable where Section: AnyObject, Row: AnyObject {
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to nil. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    func set(_ table: Table, animation: Animation = Self.defaultAnimation, rowNeedsUpdate: ((Row, Row) -> Bool)? = nil) {
        set(table, animation: animation, rowIdentifier: ObjectIdentifier.init, rowNeedsUpdate: rowNeedsUpdate)
    }
}
