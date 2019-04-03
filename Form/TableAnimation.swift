//
//  TableAnimation.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-09-30.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

public struct TableAnimation: Style, Equatable {
    public let sectionInsert: UITableView.RowAnimation
    public let sectionDelete: UITableView.RowAnimation
    public let rowInsert: UITableView.RowAnimation
    public let rowDelete: UITableView.RowAnimation

    public init(sectionInsert: UITableView.RowAnimation, sectionDelete: UITableView.RowAnimation, rowInsert: UITableView.RowAnimation, rowDelete: UITableView.RowAnimation) {
        self.sectionInsert = sectionInsert
        self.sectionDelete = sectionDelete
        self.rowInsert = rowInsert
        self.rowDelete = rowDelete
    }
}

extension TableAnimation {
    public static let `default` = TableAnimation(sectionInsert: .fade, sectionDelete: .fade, rowInsert: .top, rowDelete: .bottom)
}

public extension TableAnimation {
    static let automatic = TableAnimation(sectionInsert: .automatic, sectionDelete: .automatic, rowInsert: .automatic, rowDelete: .automatic)
    static let none = TableAnimation(sectionInsert: .none, sectionDelete: .none, rowInsert: .none, rowDelete: .none)
    static let fade = TableAnimation(sectionInsert: .fade, sectionDelete: .fade, rowInsert: .fade, rowDelete: .fade)
}

public extension UITableView {
    /// Animates `changes` using `animation`.
    /// - Note: A `.none` animation will just perform a `reloadData()`.
    func animate<Section, Row>(changes: [TableChange<Section, Row>], animation: TableAnimation = .default) {
        guard !changes.isEmpty else { return }

        guard animation != .none, window != nil else {
            reloadData()
            return
        }

        func indexPath(_ tableIndex: TableIndex) -> IndexPath {
            return IndexPath(row: tableIndex.row, section: tableIndex.section)
        }

        beginUpdates()

        changes.forEach {
            switch $0 {

            // Section updates
            case let .section(.insert(_, index)):
                insertSections(IndexSet(integer: index), with: animation.sectionInsert)
            case let .section(.delete(_, index)):
                deleteSections(IndexSet(integer: index), with: animation.sectionDelete)
            case let .section(.move(_, fromIndex, toIndex)):
                moveSection(fromIndex, toSection: toIndex)
            case let .section(.update(_, index)):
                deleteSections(IndexSet(integer: index), with: animation.sectionDelete)
                insertSections(IndexSet(integer: index), with: animation.sectionInsert)

            // Row changes
            case let .row(.insert(_, index)):
                insertRows(at: [indexPath(index)], with: animation.rowInsert)
            case let .row(.delete(_, index)):
                deleteRows(at: [indexPath(index)], with: animation.rowDelete)
            case let .row(.move(_, fromIndex, toIndex)):
                moveRow(at: indexPath(fromIndex), to: indexPath(toIndex))
            case .row(.update):
                break
            }
        }

        endUpdates()
    }
}
