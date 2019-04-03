//
//  TableViewDelegate.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-02.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A delegate conforming to `UITableViewDelegate` to work more conveniently with `Table`s.
///
///     let delegate = TableViewDelegate(table: table)
///     tableView.delegate = delegate
///     bag.hold(delegate)
///     bag += delegate.cellForIndex.set { index in ... }
///     bag += dataSource.titleForHeaderInSection.set { index in ... }
///
/// - Note: Even though you can use an instance of `self` by itself, you would most likely use it indirectly via a `TableKit` instance.
public final class TableViewDelegate<Section, Row>: ScrollViewDelegate, UITableViewDelegate {
    private let didSelectCallbacker = Callbacker<TableIndex>()
    private let didReorderCallbacker = Callbacker<(source: TableIndex, destination: TableIndex)>()
    private let willDisplayCellCallbacker = Callbacker<(UITableViewCell, TableIndex)>()
    private let didEndDisplayingCellCallbacker = Callbacker<UITableViewCell>()
    private var actions = [(UITableViewRowAction, (TableIndex) -> Bool)]()

    public var table: Table<Section, Row>
    public var viewForHeaderInSection = Delegate<Int, UIView?>()
    public var viewForFooterInSection = Delegate<Int, UIView?>()
    public var headerHeight: CGFloat = UITableView.automaticDimension
    public var footerHeight: CGFloat = UITableView.automaticDimension
    public var cellHeight: CGFloat = UITableView.automaticDimension
    public var reorderProposition = Delegate<(from: TableIndex, to: TableIndex), TableIndex>()
    public var shouldIndentWhileEditingRow = true
    public var shouldAutomaticallyDeselect = true
    public var selectionAllowed = Delegate<TableIndex, Bool>()
    public var editingStyle = Delegate<TableIndex, UITableViewCell.EditingStyle>()

    public init(table: Table<Section, Row> = Table()) {
        self.table = table
    }

    /// MARK: UITableViewDelegate (compiler complains if moved to separate extension)

    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let tableIndex = TableIndex(indexPath, in: table) else { return false }
        return !didSelectCallbacker.isEmpty && selectionAllowed.call(tableIndex) ?? true
    }

    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let tableIndex = TableIndex(indexPath, in: table) else { return nil }
        return actions.filter { (_, isVisibleAt) in isVisibleAt(tableIndex) }.map { $0.0 }.map {
            if #available(iOS 10.0, *) { // Remove this map when dropping iOS 9
                return $0
            }
            return $0.copy() as! UITableViewRowAction // https://fabric.io/izettle/ios/apps/com.izettle.app/issues/58b97e4d0aeb16625bf3e5a4
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableIndex = TableIndex(indexPath, in: table) else { return }
        didSelectCallbacker.callAll(with: tableIndex)
        if shouldAutomaticallyDeselect {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewForHeaderInSection.call(section) ?? nil
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return viewForFooterInSection.call(section) ?? nil
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return footerHeight
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return shouldIndentWhileEditingRow
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableIndex = TableIndex(indexPath, in: table) else { return }
        willDisplayCellCallbacker.callAll(with: (cell, tableIndex))
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        didEndDisplayingCellCallbacker.callAll(with: cell)
    }

    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let sourceIndexPath = TableIndex(section: sourceIndexPath.section, row: sourceIndexPath.row)
        let toIndex = TableIndex(section: proposedDestinationIndexPath.section, row: proposedDestinationIndexPath.row)
        let destinationIndexPath = reorderProposition.call((from: sourceIndexPath, to: toIndex)) ?? toIndex
        didReorderCallbacker.callAll(with: (sourceIndexPath, destinationIndexPath))
        return IndexPath(row: destinationIndexPath.row, section: destinationIndexPath.section)
    }

    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let tableIndex = TableIndex(indexPath, in: table) else { return .none }
        if let editingStyle = editingStyle.call(tableIndex) { return editingStyle }
        return self.tableView(tableView, editActionsForRowAt: indexPath)?.isEmpty == false ? .delete : .none  // .delete is needed to enable swipe actions..
    }
}

public extension TableViewDelegate {
    var didSelect: Signal<TableIndex> {
        return Signal(callbacker: didSelectCallbacker)
    }

    var didSelectRow: Signal<Row> {
        return didSelect.map { self.table[$0] }
    }

    var willDisplayCell: Signal<(UITableViewCell, TableIndex)> {
        return Signal(callbacker: willDisplayCellCallbacker)
    }

    var didEndDisplayingCell: Signal<UITableViewCell> {
        return Signal(callbacker: didEndDisplayingCellCallbacker)
    }

    var didReorderRow: Signal<(source: TableIndex, destination: TableIndex)> {
        return Signal(callbacker: didReorderCallbacker)
    }

    func installAction(title: DisplayableString, style: UITableViewRowAction.Style = .normal, backgroundColor: UIColor? = nil, isVisibleAt: @escaping (TableIndex) -> Bool = { _ in true }) -> Signal<TableIndex> {
        return Signal { callback in
            let callbacker = Callbacker<TableIndex>()
            let action = UITableViewRowAction(title: title, style: style, handler: { (_, indexPath) in
                guard let tableIndex = TableIndex(indexPath, in: self.table) else { return }
                callbacker.callAll(with: tableIndex)
            })
            action.backgroundColor = backgroundColor
            self.actions.append((action, isVisibleAt))

            let bag = DisposeBag()
            bag += callbacker.addCallback(callback)
            bag += {
                _ = self.actions.firstIndex { $0.0 == action }.map { self.actions.remove(at: $0) }
            }

            return bag
        }
    }
}

public extension UITableViewRowAction {
    convenience init(title: DisplayableString, style: UITableViewRowAction.Style = .normal, handler: @escaping ((UITableViewRowAction, IndexPath) -> Void)) {
        self.init(style: style, title: title.displayValue, handler: handler)
        accessibilityLabel = title.displayValue
    }
}
