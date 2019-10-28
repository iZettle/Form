//
//  CollectionViewDelegate.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-09-28.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A delegate conforming to `UICollectionViewDelegate` to work more conveniently with `Table` instances.
///
///     let delegate = CollectionViewDelegate(table: table)
///     collectionView.delegate = delegate
///     bag.hold(delegate)
///     bag += delegate.didSelectRow.onValue { row in ... }
///
/// - Note: Even though you can use an instance of `self` by itself, you would most likely use it indirectly via a `CollectionKit` instance.
public final class CollectionViewDelegate<Section, Row>: ScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public var table: Table<Section, Row>
    public let reordering = Delegate<(source: TableIndex, proposed: TableIndex), TableIndex>()
    private let didSelectCallbacker = Callbacker<TableIndex>()
    private let didEndDisplayingCellCallbacker = Callbacker<UICollectionViewCell>()
    private let didEndDisplayingSupplementaryViewCallbacker = Callbacker<(kind: String, view: UICollectionReusableView)>()
    private let willDisplayCellCallbacker = Callbacker<(UICollectionViewCell, TableIndex)>()
    public var sizeForItemAt = Delegate<TableIndex, CGSize>()
    public var shouldAutomaticallyDeselect = true

    public init(table: Table<Section, Row> = Table()) {
        self.table = table
    }

    // MARK: UICollectionViewDelegate (compiler complains if moved to separate extension)

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tableIndex = TableIndex(indexPath, in: table) else { return }
        didSelectCallbacker.callAll(with: tableIndex)
        if shouldAutomaticallyDeselect {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        let source = TableIndex(section: originalIndexPath.section, row: originalIndexPath.row)
        let proposed = TableIndex(section: proposedIndexPath.section, row: proposedIndexPath.row)
        guard let index = reordering.call((source, proposed)), let indexPath = IndexPath(index, in: self.table) else {
            return proposedIndexPath
        }
        return indexPath
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        didEndDisplayingCellCallbacker.callAll(with: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        didEndDisplayingSupplementaryViewCallbacker.callAll(with: (elementKind, view))
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let tableIndex = TableIndex(indexPath, in: table) else { return }
        willDisplayCellCallbacker.callAll(with: (cell, tableIndex))
    }

    // MARK: UICollectionViewDelegateFlowLayout (compiler complains if moved to separate extension)

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let collectionViewFlowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return collectionViewLayout.collectionViewContentSize
        }
        let fallbackSize = collectionViewFlowLayout.itemSize
        guard let tableIndex = TableIndex(indexPath, in: table) else { return fallbackSize }
        return sizeForItemAt.call(tableIndex) ?? fallbackSize
    }
}

public extension CollectionViewDelegate {
    var didSelect: Signal<TableIndex> {
        return Signal(callbacker: didSelectCallbacker)
    }

    var didSelectRow: Signal<Row> {
        return didSelect.map { self.table[$0] }
    }

    var didEndDisplayingCell: Signal<UICollectionViewCell> {
        return Signal(callbacker: didEndDisplayingCellCallbacker)
    }

    var willDisplayCell: Signal<(UICollectionViewCell, TableIndex)> {
        return Signal(callbacker: willDisplayCellCallbacker)
    }

    func didEndDisplayingSupplementaryView(forKind kind: String) -> Signal<UICollectionReusableView> {
        return Signal(callbacker: didEndDisplayingSupplementaryViewCallbacker).compactMap { $0.kind == kind ? $0.view : nil }
    }
}
