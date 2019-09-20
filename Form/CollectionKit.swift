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
///     let collectionKit = CollectionKit(table: table, layout: layout)
///     bag += viewController.install(collectionKit)
public final class CollectionKit<Section, Row> {
    private let internalBag: DisposeBag?
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
            dataSource.table = newValue
            delegate.table = newValue
            view.reloadData()
            callbacker.callAll(with: newValue)
        }
    }

    /// - Parameters:
    ///   - table: The data model managed by the kit. Defaults to an empty table.
    ///   - layout: The collection view layout to be used.
    ///   - externalBag: Optional bag to hold the subscriptions to the collection view. Will retain `self` until disposed.
    ///   - cellForRow: A block that creates a cell for a given index path.
    public init(table: Table = Table(), layout: UICollectionViewLayout, holdIn externalBag: DisposeBag?, cellForRow: @escaping (UICollectionView, Row, TableIndex) -> UICollectionViewCell) {
        self.view = UICollectionView.defaultCollection(withLayout: layout)

        let bag: DisposeBag
        if let externalBag = externalBag {
            // If external bag is passed, retain `self` but don't retain the bag by `self`
            bag = externalBag
            self.internalBag = nil
            externalBag.hold(self)
        } else {
            // If external bag is not passed, `self` retains the bag where subscriptions will be stored
            // and `self` need to be retained externally for the view functionality to be kept
            let internalBag = DisposeBag()
            self.internalBag = internalBag
            bag = internalBag
        }

        dataSource.table = table
        delegate.table = table
        view.delegate = delegate
        view.dataSource = dataSource

        bag += dataSource.cellForIndex.set { [weak self] index in
            guard let `self` = self else { return UICollectionViewCell() }
            return cellForRow(self.view, self.table[index], index)
        }

        // Reordering
        bag += dataSource.didReorderRow.with(weak: self).onValue { reorder, `self` in
            // Auto update the table
            self.table.moveElement(from: reorder.source, to: reorder.destination)
        }

        bag += delegate.didEndDisplayingCell.onValue { cell in
            cell.releaseBag(forType: Row.self)
        }

        bag += { [weak self] in
            for cell in self?.view.visibleCells ?? [] {
                cell.releaseBag(forType: Row.self)
            }
        }
    }
}

extension CollectionKit: SignalProvider {
    public var providedSignal: ReadWriteSignal<Table> {
        return ReadSignal(capturing: self.table, callbacker: callbacker).writable { self.table = $0 }
    }
}

public extension CollectionKit {
    /// Creates a new instance
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    convenience init(table: Table = Table(), layout: UICollectionViewLayout, cellForRow: @escaping (UICollectionView, Row, TableIndex) -> UICollectionViewCell) {
        self.init(table: table, layout: layout, holdIn: nil, cellForRow: cellForRow)
    }

    @available(*, deprecated, message: "REMOVE ME use `init(table:layout:holdIn:cellForRow:)` instead")
    convenience init(table: Table = Table(), layout: UICollectionViewLayout, bag: DisposeBag, cellForRow: @escaping (UICollectionView, Row, TableIndex) -> UICollectionViewCell) {
        self.init(table: table, layout: layout, holdIn: bag, cellForRow: cellForRow)
    }
}

public extension CollectionKit where Row: Reusable, Row.ReuseType: ViewRepresentable {
    /// Creates a new instance that will setup `cellForRow` to produce cells using `Row`'s conformance to `Reusable`
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    convenience init(table: Table = Table(), layout: UICollectionViewLayout) {
        self.init(table: table, layout: layout) { collection, cell, index in
            return collection.dequeueCell(forItem: cell, at: IndexPath(row: index.row, section: index.section))
        }
    }

    @available(*, deprecated, message: "REMOVE ME use `init(table:layout:holdIn:)` instead")
    convenience init(table: Table = Table(), layout: UICollectionViewLayout, bag: DisposeBag) {
        self.init(table: table, layout: layout, holdIn: bag)
    }

    convenience init(table: Table = Table(), layout: UICollectionViewLayout, holdIn externalBag: DisposeBag) {
        self.init(table: table, layout: layout, holdIn: externalBag) { collection, cell, index in
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
        dataSource.table = table
        delegate.table = table

        let changes = from.changes(toBuild: table,
                                   sectionIdentifier: sectionIdentifier,
                                   sectionNeedsUpdate: { _, _ in false },
                                   rowIdentifier: rowIdentifier,
                                   rowNeedsUpdate: rowNeedsUpdate ?? { _, _ in false })

        view.animate(changes: changes, animation: animation)

        changesCallbacker.callAll(with: changes)
        callbacker.callAll(with: table)
    }

    /// Applies given changes to the Table and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - changes: Array of `ChangeStep`
    ///   - animation: How updates should be animated
    public func apply(changes: [TableChange<Section, Row>], animation: CollectionAnimation = CollectionKit.defaultAnimation) {
        var table = self.table
        table.apply(changes)

        dataSource.table = table
        delegate.table = table

        view.animate(changes: changes, animation: animation)

        changesCallbacker.callAll(with: changes)
        callbacker.callAll(with: table)
    }
}

public extension CollectionKit {
    func registerViewForSupplementaryElement<S: Reusable>(item: @escaping (TableIndex) -> (S)) -> Disposable where S.ReuseType: ViewRepresentable {
        let kind = String(describing: S.self)
        let bag = DisposeBag()
        bag += dataSource.supplementaryElement(for: kind).set { index -> UICollectionReusableView in
            guard let indexPath = IndexPath(index, in: self.table) else {
                return UICollectionReusableView()
            }
            let item = item(index)
            let view = self.view.dequeueSupplementaryView(forItem: item, kind: kind, at: indexPath)
            return view
        }
        bag += {
            for cell in self.view.visibleSupplementaryViews(ofKind: kind) {
                cell.releaseBag(forType: S.self)
            }
        }
        bag += delegate.didEndDisplayingSupplementaryView(forKind: kind).onValue { view in
            view.releaseBag(forType: S.self)
        }
        return bag
    }
}

private extension CollectionKit {
    var changesSignal: Signal<[TableChange<Section, Row>]> {
        return Signal(callbacker: changesCallbacker)
    }
}
