//
//  CollectionAnimation.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-10-10.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

public enum CollectionAnimation {
    case none
    case animated
}

public extension CollectionAnimation {
    static let `default` = animated
}

public extension UICollectionView {
    /// Animates `changes` using `animation`.
    /// - Note: A `.none` animation will just perform a `reloadData()`.
    func animate<Section, Row>(changes: [TableChange<Section, Row>], animation: CollectionAnimation = .default) {
        guard !changes.isEmpty else { return }

        guard animation != .none, window != nil, canAnimateUpdates(with: changes) else {
            reloadData()
            return
        }

        func indexPath(_ tableIndex: TableIndex) -> IndexPath {
            return IndexPath(row: tableIndex.row, section: tableIndex.section)
        }

        performBatchUpdates({
            changes.forEach {
                switch $0 {

                // Section updates
                case let .section(.insert(_, index)):
                    insertSections(IndexSet(integer: index))
                case let .section(.delete(_, index)):
                    deleteSections(IndexSet(integer: index))
                case let .section(.move(_, fromIndex, toIndex)):
                    moveSection(fromIndex, toSection: toIndex)
                case let .section(.update(_, index)):
                    deleteSections(IndexSet(integer: index))
                    insertSections(IndexSet(integer: index))

                // Row changes
                case let .row(.insert(_, index)):
                    insertItems(at: [indexPath(index)])
                case let .row(.delete(_, index)):
                    deleteItems(at: [indexPath(index)])
                case let .row(.move(_, fromIndex, toIndex)):
                    moveItem(at: indexPath(fromIndex), to: indexPath(toIndex))
                case let .row(.update(_, index)):
                    reloadItems(at: [indexPath(index)])
                }
            }

        }, completion: nil)
    }
}

private extension UICollectionView {
    func canAnimateUpdates<Section, Row>(with changes: [TableChange<Section, Row>]) -> Bool {
        for change in changes {
            switch change {
            case .section(.insert), .section(.delete), .section(.move):
                // Disabling animation if the sections are changing since this leads to crashes when combined with row changes in those sections
                return false
            default:
                continue
            }
        }
        return true
    }
}
