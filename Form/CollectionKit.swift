//
//  CollectionKit.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-10-10.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A coordinator type for working with a collection view, its source and delegate as well as styling and configuration.
///
///     let collectionKit = CollectionKit(table: table, layout: layout, bag: bag)
///     bag += viewController.install(collectionKit)
public final class CollectionKit<Section, Row> {
    private let callbacker = Callbacker<Table>()
    private let changesCallbacker = Callbacker<[TableChange<Section, Row>]>()

    public typealias Table = Form.Table<Section, Row>

    public let view: UICollectionView
    public let dataSource = CollectionViewDataSource<Section, Row>()
    // swiftlint:disable weak_delegate
    public let delegate = CollectionViewDelegate<Section, Row>()
    // swiftlint:enable weak_delegate

    public var table: Table {
        get { return dataSource.table }
        set {
            dataSource.table = table
            delegate.table = table
            view.reloadData()
            callbacker.callAll(with: table)
        }
    }

    /// Creates a new instance
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    ///   - bag: A bag used to add collection kit activities.
    public init(table: Table = Table(), layout: UICollectionViewLayout, bag: DisposeBag, cellForRow: @escaping (UICollectionView, Row, TableIndex) -> UICollectionViewCell) {
        self.view = UICollectionView.defaultCollection(withLayout: layout)

        dataSource.table = table
        delegate.table = table
        view.delegate = delegate
        view.dataSource = dataSource

        bag += dataSource.cellForIndex.set { index in cellForRow(self.view, self.table[index], index) }

        // Reordering
        bag += dataSource.didReorderRow.onValue { (source: TableIndex, destination: TableIndex) in
            // Auto update the table
            self.table.moveElement(from: source, to: destination)
        }
    }
}

extension CollectionKit: SignalProvider {
    public var providedSignal: ReadWriteSignal<Table> {
        return ReadSignal(capturing: self.table, callbacker: callbacker).writable { self.table = $0 }
    }
}

public extension CollectionKit where Row: Reusable, Row.ReuseType: ViewRepresentable {
    /// Creates a new instance that will setup `cellForRow` to produce cells using `Row`'s conformance to `Reusable`
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    ///   - bag: A bag used to add table kit activities.
    convenience init(table: Table = Table(), layout: UICollectionViewLayout, bag: DisposeBag) {
        self.init(table: table, layout: layout, bag: bag) { collection, cell, index in
            return collection.dequeueCell(forItem: cell, at: IndexPath(row: index.row, section: index.section))
        }
    }
}

extension CollectionKit: TableAnimatable {
    public typealias CellView = UICollectionViewCell
    public static var defaultAnimation: CollectionAnimation { return .default }

    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - sectionIdentifier: Closure returning unique identity for a given section
    ///   - rowIdentifier: Closure returning unique identity for a given row
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to true. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    public func set<SectionIdentifier: Hashable, RowIdentifier: Hashable>(_ table: Table,
                                                                          animation: CollectionAnimation = CollectionKit.defaultAnimation,
                                                                          sectionIdentifier: (Section) -> SectionIdentifier,
                                                                          rowIdentifier: (Row) -> RowIdentifier,
                                                                          rowNeedsUpdate: ((Row, Row) -> Bool)?) {
        let from = self.table

        delegate.table = table
        dataSource.table = table

        let changes = from.changes(toBuild: table,
                                   sectionIdentifier: sectionIdentifier,
                                   sectionNeedsUpdate: { _, _ in false },
                                   rowIdentifier: rowIdentifier,
                                   rowNeedsUpdate: rowNeedsUpdate ?? { (_, _)  in false })

        view.animate(changes: changes, animation: animation)

        changesCallbacker.callAll(with: changes)
        callbacker.callAll(with: table)
    }
}

private extension CollectionKit {
    var changesSignal: Signal<[TableChange<Section, Row>]> {
        return Signal(callbacker: changesCallbacker)
    }
}
