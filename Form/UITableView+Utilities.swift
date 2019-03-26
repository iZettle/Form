//
//  UITableView+Utilities.swift
//  Form
//
//  Created by Emmanuel Garnier on 21/09/16.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UITableView {
    /// Will wrap any provided view in a container view that will work correctly with auto resize for constraints changes.
    var autoResizingTableHeaderView: UIView? {
        get { return (tableHeaderView as? AutoResizingTableHeaderView)?.subviews.first }
        set { tableHeaderView = newValue.map { AutoResizingTableHeaderView(embeddedView: $0, tableView: self) } }
    }

    /// Will wrap any provided view in a container view that will work correctly with auto resize for constraints changes.
    var autoResizingTableFooterView: UIView? {
        get { return (tableFooterView as? AutoResizingTableFooterView)?.subviews.first }
        set { tableFooterView = newValue.map { AutoResizingTableFooterView(embeddedView: $0, tableView: self) } }
    }
}

public extension UITableView {
    /// Will add `refreshControl` and remove it when the returned `Disposable` is being disposed.
    func install(_ refreshControl: UIRefreshControl) -> Disposable {
        if #available(iOS 10.0, *) {
            self.refreshControl = refreshControl
        } else {
            insertSubview(refreshControl, at: 0)
        }

        return Disposer {
            if #available(iOS 10.0, *) {
                self.refreshControl = nil
            } else {
                refreshControl.removeFromSuperview()
            }
        }
    }
}

extension UITableView {
    func position(at indexPath: IndexPath) -> CellPosition {
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == numberOfRows(inSection: indexPath.section) - 1
        return CellPosition(isFirst: isFirst, isLast: isLast)
    }
}

private class AutoResizingTableSubviewBase: UIView {
    weak var tableView: UITableView?
    var embeddedView: UIView

    init(embeddedView: UIView, tableView: UITableView) {
        self.tableView = tableView
        self.embeddedView = embeddedView

        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 1)) // need to have a height at the begining to prevent end of section separator bug
        embeddedView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(embeddedView)

        let rightContraint: NSLayoutConstraint = embeddedView.rightAnchor == rightAnchor
        rightContraint.priority = .required - 1
        activate(rightContraint,
                 embeddedView.leftAnchor == leftAnchor,
                 embeddedView.rightAnchor >= rightAnchor,
                 embeddedView.centerYAnchor == centerYAnchor)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class AutoResizingTableHeaderView: AutoResizingTableSubviewBase {
    override func layoutSubviews() {
        super.layoutSubviews()

        frame.size.height = embeddedView.bounds.height
        if frame.size.height == 0 { // 0 has special meaning, not what we want
            frame.size.height = .headerFooterAlmostZero
        }

        tableView?.tableHeaderView = self
    }
}

private class AutoResizingTableFooterView: AutoResizingTableSubviewBase {
    override func layoutSubviews() {
        super.layoutSubviews()

        frame.size.height = embeddedView.bounds.height
        if frame.size.height == 0 { // 0 has special meaning, not what we want
            frame.size.height = .headerFooterAlmostZero
        }

        tableView?.tableFooterView = self
    }
}
