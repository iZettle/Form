//
//  CollectionViewDataSource.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-09-28.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A data source conforming to `UICollectionViewDataSource` to work more conveniently with `Table` instances.
///
///     let dataSource = CollectionViewDataSource(table: table)
///     collectionView.dataSource = dataSource
///     bag.hold(dataSource)
///     bag += dataSource.cellForIndex.set { index in ... }
///
/// - Note: Even though you can use an instance of `self` by itself, you would most likely use it indirectly via a `CollectionKit` instance.
public final class CollectionViewDataSource<Section, Row>: NSObject, UICollectionViewDataSource {
    private var didReorderCallbacker = Callbacker<(source: TableIndex, destination: TableIndex)>()

    public var table: Table<Section, Row>
    public var cellForIndex = Delegate<TableIndex, UICollectionViewCell>()
    public var viewsForSupplementaryElement = [String: Delegate<TableIndex, UICollectionReusableView>]()

    public init(table: Table<Section, Row> = Table()) {
        self.table = table
    }

    // MARK: UICollectionViewDataSource (compiler complains if moved to separate extension)

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return table.sections[section].count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let tableIndex = TableIndex(indexPath, in: table), let cell = cellForIndex.call(tableIndex) else {
            return UICollectionViewCell()
        }
        return cell
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return table.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        didReorderCallbacker.callAll(with: (TableIndex(section: sourceIndexPath.section, row: sourceIndexPath.row), TableIndex(section: destinationIndexPath.section, row: destinationIndexPath.row)))
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return viewsForSupplementaryElement[kind]?.call(TableIndex(section: indexPath.section, row: indexPath.row)) ?? UICollectionReusableView()
    }
}

public extension CollectionViewDataSource {
    func supplementaryElement(for kind: String) -> Delegate<TableIndex, UICollectionReusableView> {
        let delegate = viewsForSupplementaryElement[kind] ?? {
            let delegate = Delegate<TableIndex, UICollectionReusableView>()
            viewsForSupplementaryElement[kind] = delegate
            return delegate
        }()
        return delegate
    }
}

public extension CollectionViewDataSource {
    var didReorderRow: Signal<(source: TableIndex, destination: TableIndex)> {
        return Signal(callbacker: didReorderCallbacker)
    }
}
