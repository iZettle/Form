//
//  RowsSelection.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-08-10.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

#if canImport(Presentation)
import Presentation

public protocol SelectableRow {
    associatedtype Identifier: Equatable
    var identifier: Identifier { get }
    func render() -> (RowView, Disposable)
}

/// Helper to work with a `MasterDetailSelection` and rows conforming to `SelectableRow` to allow updating
/// selection and hidden state on the rendered `RowView`s. Useful when the master view is not a table view but built
/// using `RowView`s.
public struct RowsSelection<Row: SelectableRow> {
    private let signalAndRowsProperty = ReadWriteSignal<[AppendedRow]>([])
    private var signalAndRows: [AppendedRow] {
        get { return signalAndRowsProperty.value }
        set { signalAndRowsProperty.value = newValue }
    }
    private let lazySelection: Lazy<MasterDetailSelection<[Row]>>

    public typealias AppendedRow = (rowSignal: RowAndProvider<Signal<()>>, row: ReadSignal<Row?>)

    /// Returns the underlying master detail selection instance.
    public var selection: MasterDetailSelection<[Row]> {
        return lazySelection.unbox
    }

    /// Creates a new instance.
    /// - Parameters:
    ///   - isCollapsed: Whether or not details are displayed.
    ///   - isInline: Whether or not are row should will be displayed in details view or not.
    ///   - bag: A bag used to add row selection activities.
    public init(isCollapsed: ReadSignal<Bool?>, isInline: @escaping (Row) -> Bool = { _ in true }, bag: DisposeBag) {
        let visibleRows = signalAndRowsProperty.flatMapLatest { rows in
            Flow.combineLatest(rows.map { $0.1 }).map { $0.compactMap { $0 }.filter(isInline) }
        }
        lazySelection = Lazy(MasterDetailSelection(elements: visibleRows, isSame: { $0.identifier == $1.identifier }, isCollapsed: isCollapsed))

        // Render rows
        bag += forEach { rowSignal, row in
            guard let row = row else {
                rowSignal.isHidden = true
                return NilDisposer()
            }

            let (rowView, disposable) = row.render()
            rowSignal.orderedViews = rowView.orderedViews
            rowSignal.isHidden = false
            return disposable
        }

        /// Maintain selection
        bag += atOnce().onValue { [self] selectedRow in
            for (rowSignal, row) in self.signalAndRows {
                guard let section = rowSignal.row.firstAncestor(ofType: SectionView.self),
                    let isSelectedSignal = section.isSelectedSignal(for: rowSignal.row) else { continue }

                if let row = row.value, let selected = selectedRow, row.identifier == selected.identifier {
                    isSelectedSignal.value = true
                } else {
                    isSelectedSignal.value = false
                }
            }
        }
    }
}

public extension RowsSelection {
    mutating func append(_ row: AppendedRow) {
        signalAndRows.append(row)
    }

    @discardableResult
    mutating func remove(id: Row.Identifier) -> Form.RowView? {
        guard let index = signalAndRows.firstIndex(where: { $0.row.value?.identifier == id }) else {
            return nil
        }
        return signalAndRows.remove(at: index).rowSignal.row
    }

    subscript(id: Row.Identifier) -> Row? {
        guard let index = selection.elements.firstIndex(where: { $0.identifier == id }) else { return nil }
        return selection.elements[index]
    }
}

public extension RowsSelection {
    /// Returns a signal for observering user selection of rows.
    var didSelect: Signal<Row> {
        return Signal { callback in
            self.forEach { rowSignal, row in
                guard let row = row else { return NilDisposer() }
                return rowSignal.onValue { callback(row) }
            }
        }
    }

    /// Selects the row with `id`
    func select(id: Row.Identifier) {
        if let index = selection.elements.firstIndex(where: { $0.identifier == id }) {
            selection.select(index: index)
        }
    }
}

extension RowsSelection: SignalProvider {
    public var providedSignal: ReadSignal<Row?> {
        return selection.map { $0?.element }
    }
}

public func +=<Row: SelectableRow>(_ rows: inout RowsSelection<Row>, _ signalAndRow: RowsSelection<Row>.AppendedRow) {
    rows.append(signalAndRow)
}

public extension SectionView {
    func append<Row: SelectableRow, P>(_ signal: ReadSignal<P?>, _ row: @escaping (P) -> Row) -> RowsSelection<Row>.AppendedRow {
        return append(signal.map { $0.map { row($0) } })
    }

    func append<Row: SelectableRow>(_ row: ReadSignal<Row?>) -> RowsSelection<Row>.AppendedRow {
        return (self.append(Form.RowView()), row)
    }

    func append<Row: SelectableRow>(_ row: Row) -> RowsSelection<Row>.AppendedRow {
        return append(ReadSignal(row))
    }

    func prepend<Row: SelectableRow>(_ row: ReadSignal<Row?>) -> RowsSelection<Row>.AppendedRow {
        return (self.prepend(Form.RowView()), row)
    }

    func prepend<Row: SelectableRow>(_ row: Row) -> RowsSelection<Row>.AppendedRow {
        return prepend(ReadSignal(row))
    }
}

private extension RowsSelection {
    func forEach(perform: @escaping (RowAndProvider<Signal<()>>, Row?) -> Disposable) -> Disposable {
        let bag = DisposeBag()
        var disposables: [ObjectIdentifier: Disposable] = [:]
        bag += signalAndRowsProperty.atOnce().plain().start(with: []).latestTwo().onValue { oldRows, rows in
            let changes = oldRows.changes(toBuild: rows, identifier: { ObjectIdentifier($0.rowSignal) })

            for change in changes {
                switch change {
                case let .insert((signal, row), _):
                    let disposable = row.atOnce().onValueDisposePrevious {
                        perform(signal, $0)
                    }
                    bag += disposable
                    disposables[ObjectIdentifier(signal)] = disposable
                case let .delete(row, _):
                    disposables.removeValue(forKey: ObjectIdentifier(row.rowSignal))?.dispose()
                case .move, .update: break
                }
            }
        }

        return bag
    }
}

private final class Lazy<A> {
    private var lazy: (() -> A)!
    private var cached: A!

    public var unbox: A {
        if let value = cached {
            return value
        }
        cached = lazy()
        lazy = nil
        return cached
    }

    public init(_ value: @autoclosure @escaping () -> A) {
        lazy = value
    }

    public init(_ value: @escaping () -> A) {
        lazy = value
    }
}

#endif
