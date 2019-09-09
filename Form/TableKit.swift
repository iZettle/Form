//
//  TableKit.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-09-30.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A coordinator type for working with a table view, its source and delegate as well as styling and configuration.
///
///     let tableKit = TableKit(table: table)
///     bag += viewController.install(tableKit)
public final class TableKit<Section, Row> {
    private let bag: DisposeBag
    private let callbacker = Callbacker<Table>()
    private let changesCallbacker = Callbacker<[TableChange<Section, Row>]>()

    public typealias Table = Form.Table<Section, Row>

    public let view: UITableView
    public let dataSource = TableViewDataSource<Section, Row>()
    // swiftlint:disable weak_delegate
    public let delegate = TableViewDelegate<Section, Row>()
    // swiftlint:enable weak_delegate
    public let style: DynamicTableViewFormStyle

    public var table: Table {
        get { return dataSource.table }
        set {
            dataSource.table = newValue
            delegate.table = newValue
            view.reloadData()
            callbacker.callAll(with: newValue)
        }
    }

    /// Delegate to retreive a view to be displayed when table is empty.
    @available(*, deprecated, message: "use `viewForEmptyTable(fadeDuration:)` instead")
    public lazy var viewForEmptyTable: Delegate<(), UIView> = {
        return Delegate { [weak self] getEmptyView in
            guard let `self` = self else { return NilDisposer() }

            return self.viewForEmptyTable().set { _ in
                UIView(embeddedView: getEmptyView(()),
                       edgeInsets: UIEdgeInsets(horizontalInset: 15, verticalInset: 15),
                       pinToEdges: [.left, .right])
            }
        }
    }()

    private lazy var viewForDurationForEmptyTable: Delegate<(), (view: UIView, duration: TimeInterval)> = {
        return Delegate { [weak self] getArgs in
            guard let `self` = self else { return NilDisposer() }

            let bag = DisposeBag()
            var currentView: UIView?
            var previousDuration: TimeInterval?
            bag += self.atOnce().onValue { table in
                let args = getArgs(())

                if let prevView = currentView, let duration = previousDuration {
                    currentView = nil
                    UIView.animate(withDuration: duration,
                                   animations: { prevView.alpha = 0 },
                                   completion: { _ in prevView.removeFromSuperview()  })
                }

                if table.isEmpty {
                    let emptyView = args.view
                    emptyView.alpha = 0
                    self.view.embedAutoresizingView(emptyView)
                    self.view.sendSubviewToBack(emptyView)
                    currentView = emptyView
                    previousDuration = args.duration
                    UIView.animate(
                        withDuration: args.duration,
                        animations: { emptyView.alpha = 1 }
                    )
                }
            }

            bag += { currentView?.removeFromSuperview() }

            return bag
        }
    }()

    /// Delegate to retreive a view to be displayed when the table is empty.
    /// The view will be constrained to the edges of the table
    ///
    /// - Parameter animationDuration: The duration of the fade in/out animation when showing/hiding the empty view
    /// - Returns: A delegate object capturing the logic for creating an empty view
    public func viewForEmptyTable(fadeDuration: TimeInterval = 0.15) -> Delegate<(), UIView> {
        return Delegate { getEmptyView in
            return self.viewForDurationForEmptyTable.set { _ in
                return (view: getEmptyView(()), fadeDuration)
            }
        }
    }

    private init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, deprecatedBag: DisposeBag?, headerForSection: ((UITableView, Section) -> UIView?)? = nil, footerForSection: ((UITableView, Section) -> UIView?)? = nil, cellForRow: @escaping (UITableView, Row) -> UITableViewCell) {
        let view = view ?? UITableView.defaultTable(for: style.tableStyle)
        self.view = view
        self.style = style

        // Remove deprecatedBag parameter once deprecetated inits have been removed.
        if let deprecatedBag = deprecatedBag {
            bag = deprecatedBag
            deprecatedBag.hold(self) // Hold on to self to simulate deprecated behaviour
        } else {
            bag = DisposeBag()
        }

        dataSource.table = table
        delegate.table = table
        view.delegate = delegate
        view.dataSource = dataSource
        view.separatorStyle = .none
        view.separatorColor = .clear

        // Do no let the tableview to add insets by its self
        if #available(iOS 9.0, *) {
            view.cellLayoutMarginsFollowReadableWidth = false
        }

        view.rowHeight = UITableView.automaticDimension

        let tableHeader = UIView()
        let tableHeaderConstraint = activate(tableHeader.heightAnchor == 0)
        if view.tableHeaderView == nil {
            view.autoResizingTableHeaderView = tableHeader
        }

        let tableFooter = UIView()
        let tableFooterConstraint = activate(tableFooter.heightAnchor == 0)
        if view.tableFooterView == nil {
            view.autoResizingTableFooterView = tableFooter
        }

        bag += view.traitCollectionWithFallbackSignal.distinct().with(weak: self).atOnce().onValue { traits, `self` in
            let style = style.style(from: traits)

            view.estimatedRowHeight = style.fixedRowHeight ?? style.section.minRowHeight

            view.sectionHeaderHeight = UITableView.automaticDimension
            view.sectionFooterHeight = UITableView.automaticDimension

            if #available(iOS 11.0, *) {
                view.estimatedSectionHeaderHeight = style.fixedHeaderHeight ?? UITableView.automaticDimension
                view.estimatedSectionFooterHeight = style.fixedFooterHeight ?? UITableView.automaticDimension
            } else {
                // on iOS 10 estimated height need to be set to a positive value (the actual one doesn't seem to affect the result but might affect performance) for the size calculation to happen properly
                // https://stackoverflow.com/a/50513288
                view.estimatedSectionHeaderHeight = style.fixedHeaderHeight ?? 44
                view.estimatedSectionFooterHeight = style.fixedFooterHeight ?? 44
            }

            if view.autoResizingTableHeaderView === tableHeader {
               tableHeaderConstraint.constant = style.form.insets.top
            }

            if view.autoResizingTableFooterView === tableFooter {
                tableFooterConstraint.constant = style.form.insets.bottom
            }

            self.delegate.cellHeight = style.fixedRowHeight ?? UITableView.automaticDimension

            self.delegate.headerHeight = style.fixedHeaderHeight ?? (headerForSection == nil ? style.section.header.emptyHeight : UITableView.automaticDimension)
            if self.delegate.headerHeight == 0 { // 0 has special meaning, not what we want
                self.delegate.headerHeight = .headerFooterAlmostZero
            }

            self.delegate.footerHeight = style.fixedFooterHeight ?? (footerForSection == nil ? style.section.footer.emptyHeight : UITableView.automaticDimension)
            if self.delegate.footerHeight == 0 { // 0 has special meaning, not what we want
                self.delegate.footerHeight = .headerFooterAlmostZero
            }
        }

        bag += dataSource.cellForIndex.set { [weak self] index in
            guard let `self` = self else { return UITableViewCell() }

            let cell = cellForRow(self.view, self.table[index])
            if let indexPath = IndexPath(index, in: self.table) {
                cell.updateBackground(forStyle: style, tableView: view, at: indexPath)
            }

            // Fix for positioning the reorder control
            let bag = cell.associatedValue(forKey: &tableCellReorderBagKey, initial: DisposeBag())
            bag.dispose()
            if self.dataSource.canBeReordered.call(index) == true {
                // Need to update the resize control position..
                bag += cell.contentView.signal(for: \.frame).distinct().onValue { [weak cell] _ in
                    guard let cell = cell, cell.reorderControlView != nil else { return }
                    cell.applyFormStyle(style.style(from: cell.traitCollectionWithFallback))
                }
            }

            return cell
        }

        bag += delegate.didEndDisplayingCell.onValue { cell in
            cell.releaseBag(forType: Row.self)
        }

        bag += {
            for cell in view.visibleCells {
                cell.releaseBag(forType: Row.self)
            }
        }

        // Reordering
        bag += delegate.didReorderRow.with(weak: self).onValue { reorder, `self` in
            self.updatePositionsOfVisibleCells { index in
                self.adjustedPosition(at: index, withReorderingFrom: reorder.source, to: reorder.destination)
            }
        }

        bag += dataSource.willReorder.with(weak: self).onValue { reorder, `self` in
            // Auto update the table
            self.table.moveElement(from: reorder.source, to: reorder.destination)
            DispatchQueue.main.async {
                self.updatePositionsOfVisibleCells()
            }
        }

        /// Will keep a ref to the dataSource and delegate until the table view is moved away from the window
        bag += { [tableView = view, dataSource = dataSource, delegate = delegate] in
            tableView.hasWindowSignal.atOnce().filter { !$0 }.future.always {
                _ = (dataSource, delegate)
            }
        }

        if let hfs = headerForSection {
            bag += delegate.viewForHeaderInSection.set { [weak self] section in
                guard let `self` = self else { return nil }
                return hfs(self.view, self.table.sections[section].value)
            }
        } else {
            bag += delegate.viewForHeaderInSection.set { [weak self]  _ in
                self?.view.dequeueHeaderFooterView(using: nil, style: style.header, formStyle: style.form)
            }
        }

        if let ffs = footerForSection {
            bag += delegate.viewForFooterInSection.set { [weak self] section in
                guard let `self` = self else { return nil }
                return ffs(self.view, self.table.sections[section].value)
            }
        } else {
            bag += delegate.viewForFooterInSection.set { [weak self] _ in
                self?.view.dequeueHeaderFooterView(using: nil, style: style.footer, formStyle: style.form)
            }
        }
    }
}

public extension TableKit {
    /// Creates a new instance
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, headerForSection: ((UITableView, Section) -> UIView?)? = nil, footerForSection: ((UITableView, Section) -> UIView?)? = nil, cellForRow: @escaping (UITableView, Row) -> UITableViewCell) {
        self.init(table: table, style: style, view: view, deprecatedBag: nil, headerForSection: headerForSection, footerForSection: footerForSection, cellForRow: cellForRow)
    }

    @available(*, deprecated, message: "use `init(table:style:view:headerForSection:footerForSection:cellForRow:)` instead")
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, bag: DisposeBag, headerForSection: ((UITableView, Section) -> UIView?)? = nil, footerForSection: ((UITableView, Section) -> UIView?)? = nil, cellForRow: @escaping (UITableView, Row) -> UITableViewCell) {
        self.init(table: table, style: style, view: view, deprecatedBag: bag, headerForSection: headerForSection, footerForSection: footerForSection, cellForRow: cellForRow)
    }
}

public extension TableKit where Row: Reusable, Row.ReuseType: ViewRepresentable {
    /// Creates a new instance that will setup `cellForRow` to produce cells using `Row`'s conformance to `Reusable`
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, headerForSection: ((UITableView, Section) -> UIView?)? = nil, footerForSection: ((UITableView, Section) -> UIView?)? = nil) {
        self.init(table: table, style: style, view: view, headerForSection: headerForSection, footerForSection: footerForSection) { table, row in
            table.dequeueCell(forItem: row, style: style)
        }
    }

    @available(*, deprecated, message: "use `init(table:style:view:headerForSection:footerForSection:)` instead")
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, bag: DisposeBag, headerForSection: ((UITableView, Section) -> UIView?)? = nil, footerForSection: ((UITableView, Section) -> UIView?)? = nil) {
        self.init(table: table, style: style, view: view, deprecatedBag: bag, headerForSection: headerForSection, footerForSection: footerForSection) { table, row in
            table.dequeueCell(forItem: row, style: style)
        }
    }
}

public extension TableKit where Row: Reusable, Row.ReuseType: ViewRepresentable, Section: Reusable, Section.ReuseType: ViewRepresentable {
    /// Creates a new instance that will setup `cellForRow` and `headerForSection` to produce cells and sections using `Row`'s and `Section`'s conformances to `Reusable`.
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, footerForSection: ((UITableView, Section) -> UIView?)? = nil) {
        self.init(table: table, style: style, view: view, headerForSection: { table, section in
            table.dequeueHeaderFooterView(forItem: section, style: style.header, formStyle: style.form)
        }, footerForSection: footerForSection, cellForRow: { table, row in
            table.dequeueCell(forItem: row, style: style)
        })
    }

    @available(*, deprecated, message: "use `init(table:style:view:footerForSection:)` instead")
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, bag: DisposeBag, footerForSection: ((UITableView, Section) -> UIView?)? = nil) {
        self.init(table: table, style: style, view: view, deprecatedBag: bag, headerForSection: { table, section in
            table.dequeueHeaderFooterView(forItem: section, style: style.header, formStyle: style.form)
        }, footerForSection: footerForSection, cellForRow: { table, row in
            table.dequeueCell(forItem: row, style: style)
        })
    }
}

public extension TableKit where Row: Reusable, Row.ReuseType: ViewRepresentable, Section: HeaderFooterReusable, Section.Header.ReuseType: ViewRepresentable, Section.Footer.ReuseType: ViewRepresentable {
    /// Creates a new instance
    /// - Parameters:
    ///   - table: The initial table. Defaults to an empty table.
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil) {
        self.init(table: table, style: style, view: view, headerForSection: { table, section in
            table.dequeueHeaderFooterView(forItem: section.header, style: style.header, formStyle: style.form, reuseIdentifier: "header")
        }, footerForSection: { table, section in
            table.dequeueHeaderFooterView(forItem: section.footer, style: style.footer, formStyle: style.form, reuseIdentifier: "footer")
        }, cellForRow: { table, row in
            table.dequeueCell(forItem: row, style: style)
        })
    }

    @available(*, deprecated, message: "use `init(table:style:view)` instead")
    convenience init(table: Table = Table(), style: DynamicTableViewFormStyle = .default, view: UITableView? = nil, bag: DisposeBag) {
        self.init(table: table, style: style, view: view, deprecatedBag: bag, headerForSection: { table, section in
            table.dequeueHeaderFooterView(forItem: section.header, style: style.header, formStyle: style.form, reuseIdentifier: "header")
        }, footerForSection: { table, section in
            table.dequeueHeaderFooterView(forItem: section.footer, style: style.footer, formStyle: style.form, reuseIdentifier: "footer")
        }, cellForRow: { table, row in
            table.dequeueCell(forItem: row, style: style)
        })
    }
}

extension TableKit: SignalProvider {
    public var providedSignal: ReadWriteSignal<Table> {
        return ReadSignal(capturing: self.table, callbacker: callbacker).writable(signalOnSet: true) { self.table = $0 }
    }
}

extension TableKit: TableAnimatable {
    public typealias CellView = UITableViewCell
    public static var defaultAnimation: TableAnimation { return .default }

    /// Sets table to `table` and calculates and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - table: The new table
    ///   - animation: How updates should be animated
    ///   - sectionIdentifier: Closure returning unique identity for a given section
    ///   - rowIdentifier: Closure returning unique identity for a given row
    ///   - rowNeedsUpdate: Optional closure indicating whether two rows with equal identifiers have any updates.
    ///           Defaults to true. If provided, unnecessary reconfigure calls to visible rows could be avoided.
    public func set<SectionIdentifier: Hashable, RowIdentifier: Hashable>(_ table: Table,
                                                                          animation: TableAnimation = TableKit.defaultAnimation,
                                                                          sectionIdentifier: (Section) -> SectionIdentifier,
                                                                          rowIdentifier: (Row) -> RowIdentifier,
                                                                          rowNeedsUpdate: ((Row, Row) -> Bool)? = { _, _ in true }) {

        let from = self.table
        dataSource.table = table
        delegate.table = table

        let changes = from.changes(toBuild: table,
                                   sectionIdentifier: sectionIdentifier,
                                   sectionNeedsUpdate: { _, _ in false },
                                   rowIdentifier: rowIdentifier,
                                   rowNeedsUpdate: rowNeedsUpdate ?? { _, _ in true })

        view.animate(changes: changes, animation: animation)

        var hasReconfiguredCells = false
        for indexPath in view.indexPathsForVisibleRows ?? [] {
            guard let tableIndex = TableIndex(indexPath, in: self.table) else { continue }
            let row = table[tableIndex]
            guard let index = from.firstIndex(where: { rowIdentifier(row) == rowIdentifier($0) }) else { continue }

            if let cell = view.cellForRow(at: indexPath) {
                cell.updateBackground(forStyle: style, tableView: view, at: indexPath)

                let old = from[index]
                guard rowNeedsUpdate?(old, row) != false else {
                    continue
                }

                cell.reconfigure(old: old, new: row)
                hasReconfiguredCells = true
            }
        }

        /// To to refresh cells where the cell height has changed.
        if hasReconfiguredCells {
            view.beginUpdates()
            view.endUpdates()
        }

        changesCallbacker.callAll(with: changes)
        callbacker.callAll(with: table)
    }

    /// Applies given changes to the Table and animates the changes using the provided parameters.
    /// - Parameters:
    ///   - changes: Array of `ChangeStep`
    ///   - animation: How updates should be animated
    public func apply(changes: [TableChange<Section, Row>], animation: TableAnimation = TableKit.defaultAnimation) {
        var table = self.table
        table.apply(changes)
        dataSource.table = table
        delegate.table = table

        view.animate(changes: changes, animation: animation)

        changesCallbacker.callAll(with: changes)
        callbacker.callAll(with: table)
    }
}

public extension TableKit {
    /// Scrolls automatically to inserted rows.
    /// - Parameter position: A constant that identifies a relative position in the table view (top, middle, bottom).
    /// - Parameter indexPath: Closure with the new inserted table indices as parameter and returning the table index to scroll to.
    ///     Defaults to scroll to the first inserted row.
    func scollToRevealInsertedRows(position: UITableView.ScrollPosition = .none, indexPath: @escaping ([TableIndex]) -> TableIndex? = { return $0.first }) -> Disposable {
        // throttle 0 so it does not conflict with the insertion animation
        return Flow.combineLatest(view.hasWindowSignal.atOnce().plain(), changesSignal).compactMap { $0 ? $1 : nil }.debounce(0).onValue { (changes) in
            let insertions = changes.compactMap { change -> TableIndex? in
                guard case .row(let rowChange) = change, case .insert(_, let index) = rowChange else { return nil }
                return index
            }
            guard let index = indexPath(insertions), let indexPath = IndexPath(index, in: self.table) else { return }

            self.view.scrollToRow(at: indexPath, at: position, animated: true)
        }
    }
}

extension TableKit {
    // The view's `autoResizingTableHeaderView`.
    public var headerView: UIView? {
        get { return view.autoResizingTableHeaderView }
        set { view.autoResizingTableHeaderView = newValue }
    }

    // The view's `autoResizingTableFooterView`.
    public var footerView: UIView? {
        get { return view.autoResizingTableFooterView }
        set { view.autoResizingTableFooterView = newValue }
    }
}

public extension TableIndex {
    /// Tries to create an instance based on a `indexPath`'s secion and row to be used in `table`.
    init?<S, R>(_ indexPath: IndexPath, in table: Table<S, R>) {
        let index = TableIndex(section: indexPath.section, row: indexPath.row)
        guard table.isValidIndex(index) else { return nil }
        self = index
    }
}

public extension IndexPath {
    /// Tries to create an instance based on a `tableIndex`'s section and row where table index comes from `table`
    init?<S, R>(_ tableIndex: TableIndex, in table: Table<S, R>) {
        guard table.isValidIndex(tableIndex) else { return nil }
        self.init(row: tableIndex.row, section: tableIndex.section)
    }
}

#if canImport(Presentation)
import Presentation

public extension MasterDetailSelection where Elements.Index == TableIndex {
    func bindTo<Row, Section>(_ tableKit: TableKit<Row, Section>) -> Disposable {
        let bag = DisposeBag()
        tableKit.delegate.shouldAutomaticallyDeselect = false
        bag += self.atOnce().latestTwo().onValue { prev, current in
            if let index = current?.index {
                guard let indexPath = IndexPath(index, in: tableKit.table) else { return }
                let isVisible = tableKit.view.indexPathsForVisibleRows?.contains(indexPath) ?? false
                let scrollPosition: UITableView.ScrollPosition
                if let prevIndex = prev?.index {
                    scrollPosition = (prevIndex < index ? .bottom : .top)
                } else {
                    scrollPosition = .middle
                }
                tableKit.view.selectRow(at: indexPath, animated: true, scrollPosition: isVisible ? .none : scrollPosition)
            } else if let prevIndex = prev?.index {
                guard let indexPath = IndexPath(prevIndex, in: tableKit.table) else { return }
                tableKit.view.deselectRow(at: indexPath, animated: true)
            }
        }

        bag += tableKit.delegate.didSelect.onValue { index in
            self.select(index: index)
        }

        tableKit.delegate.shouldAutomaticallyDeselect = false

        return bag
    }
}

#endif

extension CGFloat {
    static let headerFooterAlmostZero: CGFloat = 0.0000001
}

private extension Table {
    func isValidIndex(_ index: TableIndex) -> Bool {
        guard 0..<self.sections.count ~= index.section, 0..<self.sections[index.section].count ~= index.row else { return false }
        return true
    }
}

private extension TableKit {
    func updatePositionsOfVisibleCells() {
        updatePositionsOfVisibleCells {
            guard let indexPath = IndexPath($0, in: table) else { return .unique }
            return self.view.position(at: indexPath)

        }
    }

    func updatePositionsOfVisibleCells(position: (_ at: TableIndex) -> CellPosition) {
        for cell in self.view.visibleCells {
            guard let index = self.view.indexPath(for: cell), let tableIndex = TableIndex(index, in: table) else { continue }
            cell.updatePosition(position: position(tableIndex))
        }
    }

    func adjustedPosition(at index: TableIndex, withReorderingFrom source: TableIndex, to destination: TableIndex) -> CellPosition {
        let movingRow = source == index
        var adjustedIndex = movingRow ? destination : index

        var adjustedNbrOfRowsInSection =  view.numberOfRows(inSection: adjustedIndex.section)
        if source.section == adjustedIndex.section { // simulate removing the row
            if adjustedIndex.row > source.row && !movingRow {
                adjustedIndex = TableIndex(section: adjustedIndex.section, row: adjustedIndex.row - 1)
            }
            adjustedNbrOfRowsInSection -= 1
        }
        if destination.section == adjustedIndex.section { // simulate adding the row
            if adjustedIndex.row >= destination.row && !movingRow {
                adjustedIndex = TableIndex(section: adjustedIndex.section, row: adjustedIndex.row + 1)
            }
            adjustedNbrOfRowsInSection += 1
        }

        let isFirst = adjustedIndex.row == 0
        let isLast = adjustedIndex.row == adjustedNbrOfRowsInSection - 1
        return CellPosition(isFirst: isFirst, isLast: isLast)
    }

    var changesSignal: Signal<[TableChange<Section, Row>]> {
        return Signal(callbacker: changesCallbacker)
    }
}

private var delegateSourceKey = false
private var tableCellReorderBagKey = false
