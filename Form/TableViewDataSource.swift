//
//  TableViewDataSource.swift
//  PurchaseHistory
//
//  Created by Måns Bernhardt on 2016-01-28.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A data source conforming to `UITableViewDataSource` to work more conveniently with `Table` instances.
///
///     let dataSource = TableViewDataSource(table: table)
///     tableView.dataSource = dataSource
///     bag.hold(dataSource)
///     bag += dataSource.cellForIndex.set { index in ... }
///
/// - Note: Even though you can use an instance of `self` by itself, you would most likely use it indirectly via a `TableKit` instance.
public final class TableViewDataSource<Section, Row>: NSObject, UITableViewDataSource {
    private var willReorderCallbacker = Callbacker<(source: TableIndex, destination: TableIndex)>()
    private var didReorderCallbacker = Callbacker<(source: TableIndex, destination: TableIndex)>()

    public var table: Table<Section, Row>
    public var cellForIndex = Delegate<TableIndex, UITableViewCell>()
    public var titleForHeaderInSection = Delegate<Int, String?>()
    public var canBeReordered = Delegate<TableIndex, Bool>()

    public init(table: Table<Section, Row> = Table()) {
        self.table = table
    }

    // MARK: UITableViewDataSource (compiler complains if moved to separate extension)

    public func numberOfSections(in tableView: UITableView) -> Int {
        return table.sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return table.sections[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableIndex = TableIndex(indexPath, in: table), let cell = cellForIndex.call(tableIndex) else {
            return UITableViewCell(style: .default, reuseIdentifier: #function)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeaderInSection.call(section) ?? nil
    }

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let tableIndex = TableIndex(indexPath, in: table), let canReorder = canBeReordered.call(tableIndex) else {
            return false
        }
        return canReorder
    }

    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        willReorderCallbacker.callAll(with: (TableIndex(section: sourceIndexPath.section, row: sourceIndexPath.row), TableIndex(section: destinationIndexPath.section, row: destinationIndexPath.row)))
        didReorderCallbacker.callAll(with: (TableIndex(section: sourceIndexPath.section, row: sourceIndexPath.row), TableIndex(section: destinationIndexPath.section, row: destinationIndexPath.row)))
    }
}

public extension TableViewDataSource {
    var willReorder: Signal<(source: TableIndex, destination: TableIndex)> {
        return Signal(callbacker: willReorderCallbacker)
    }

    var didReorder: Signal<(source: TableIndex, destination: TableIndex)> {
        return Signal(callbacker: didReorderCallbacker)
    }
}
