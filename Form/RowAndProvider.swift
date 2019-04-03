//
//  RowAndProvider.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-26.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A `RowView` and a provider of type `Provider`
/// When appending or prepending a view that conforms to `SignalProvider` such
/// as `UISwitch`, to a `SectionView` the return will be an instance of self instead of just a `RowView`.
/// By returning both a row view and provider one can write:
///
///     row = section.appendRow(...).append(UISwitch())
///     bag += row.onValue { }
///
/// Or even more succinct:
///
///     bag += section.appendRow(...).append(UISwitch()).onValue { ... }
public final class RowAndProvider<Provider: SignalProvider> {
    public let row: RowView
    public let provider: Provider

    public init(row: RowView, provider: Provider) {
        self.row = row
        self.provider = provider
    }
}

extension RowAndProvider: SignalProvider {
    public var providedSignal: CoreSignal<Provider.Kind, Provider.Value> { return provider.providedSignal }
}

extension RowAndProvider: ViewRepresentable {
    public var viewRepresentation: UIView { return row.viewRepresentation }
}

public extension RowAndProvider where Provider: UIView {
    /// Creates a new instance with Row containt `provider` and provider set to `provider`.
    convenience init(_ provider: Provider) {
        self.init(row: RowView(provider), provider: provider)
    }
}

public extension RowAndProvider {
    var isHidden: Bool {
        get { return row.isHidden }
        set { row.isHidden = newValue }
    }
}

public extension RowAndProvider {
    subscript<Value>(animated keyPath: ReferenceWritableKeyPath<RowAndProvider, Value>) -> Value {
        get {
            return self[keyPath: keyPath]
        }
        set {
            guard row.window != nil else {
                self[keyPath: keyPath] = newValue
                return
            }

            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                self[keyPath: keyPath] = newValue
            })
        }
    }
}

extension RowAndProvider: SubviewOrderable {
    public var orderedViews: [UIView] {
        get { return row.orderedViews }
        set { row.orderedViews = newValue }
    }
}

public extension RowAndProvider {
    /// Appends `view` and returns `self` and `view` in a `RowAndProvider`.
    /// - Note: If you run into ambiguities or don't want use this overload casting to `UIView` such as `append(control as UIView)`
    @discardableResult
    func append<View: UIView & SignalProvider>(_ view: View) -> RowAndProvider<View> {
        append(view as UIView)
        return RowAndProvider<View>(row: row, provider: view)
    }

    /// Prepends `view` and returns `self` and `view` in a `RowAndProvider`.
    /// - Note: If you run into ambiguities or don't want use this overload casting to `UIView` such as `append(control as UIView)`
    @discardableResult
    func prepend<View: UIView & SignalProvider>(_ view: View) -> RowAndProvider<View> {
        prepend(view as UIView)
        return RowAndProvider<View>(row: row, provider: view)
    }
}

public extension SectionView {
    /// Appends a `RowView` with `views`.
    @discardableResult
    func appendRow(_ views: [UIView]) -> RowAndProvider<Signal<()>> {
        let row = RowView(views)
        append(row as UIView)
        return RowAndProvider(row: row, provider: selectSignal(for: row)!)
    }

    /// Appends a `RowView` with `views`.
    @discardableResult
    func appendRow(_ views: UIView...) -> RowAndProvider<Signal<()>> {
        return appendRow(views)
    }

    /// Appends a `RowView` with a title
    /// - Parameters:
    ///    - appendSpacer: Whether a `.spacer` we should be appended to move succeeding views to the right. Defaults to true.
    @discardableResult
    func appendRow(title: DisplayableString, style: TextStyle = TitleSubtitleStyle.default.title, appendSpacer: Bool = true) -> RowAndProvider<Signal<()>> {
        return append(RowView(title: title, style: style, appendSpacer: appendSpacer))
    }

    /// Appends a `RowView` with a title at the top and subtile at the bottom
    /// - Parameters:
    ///    - appendSpacer: Whether a `.spacer` we should be appended to move succeeding views to the right. Defaults to true.
    @discardableResult
    func appendRow(title: DisplayableString, subtitle: DisplayableString, style: TitleSubtitleStyle = .default, appendSpacer: Bool = true) -> RowAndProvider<Signal<()>> {
        return append(RowView(title: title, subtitle: subtitle, style: style, appendSpacer: appendSpacer))
    }

    /// Appends a `RowView` with `view` and returns `self` and `view` in a `RowAndProvider`.
    /// - Note: If you run into ambiguities or don't want use this overload casting to `UIView` such as `appendRow(control as UIView)`
    @discardableResult
    func appendRow<View: UIView & SignalProvider>(_ view: View) -> RowAndProvider<View> {
        let row = RowView(view)
        append(row as UIView)
        return RowAndProvider(row: row, provider: view)
    }
}

public extension SectionView {
    /// Prepends `row` and returns a section view and a signal for observing row selections.
    @discardableResult
    func prepend(_ row: RowView) -> RowAndProvider<Signal<()>> {
        let sectionRow = _addRow(with: row.orderedViews) { $0.prepend($1) }
        return RowAndProvider(row: sectionRow, provider: selectSignal(for: sectionRow)!)
    }

    /// Prepends `row` and returns a section view and the `row`'s provider.
    @discardableResult
    func prepend<Provider: SignalProvider>(_ row: RowAndProvider<Provider>) -> RowAndProvider<Provider> {
        return RowAndProvider(row: prepend(row.row).row, provider: row.provider)
    }

    /// Append `row` and returns a section view and a signal for observing row selections.
    @discardableResult
    func append(_ row: RowView) -> RowAndProvider<Signal<()>> {
        append(row as UIView)
        return RowAndProvider(row: row, provider: selectSignal(for: row)!)
    }

    /// Appends `row` and returns a section view and the `row`'s provider.
    @discardableResult
    func append<Provider: SignalProvider>(_ row: RowAndProvider<Provider>) -> RowAndProvider<Provider> {
        return RowAndProvider(row: append(row.row).row, provider: row.provider)
    }

    /// Appends two alternative rows, to show for either landscape or portrait orientation.
    /// Will dynamically switch between the two alternative rows until the provided `bag` is being disposed.
    @discardableResult
    func append(landscape: RowView, portrait: RowView, bag: DisposeBag) -> RowAndProvider<Signal<()>> {
        let sectionRow = _append(RowView())

        bag += orientationSignal.atOnce().onValue {
            sectionRow.orderedViews = ($0.isLandscape ? landscape : portrait).orderedViews
        }

        return RowAndProvider(row: sectionRow, provider: selectSignal(for: sectionRow)!)
    }

    func remove<Provider>(_ row: RowAndProvider<Provider>) {
        guard let index = self.orderedViews.firstIndex(of: row.row) else { return }
        self.orderedViews.remove(at: index)
    }

    func remove(_ sectionRow: RowView) {
        guard let index = self.orderedViews.firstIndex(of: sectionRow) else { return }
        self.orderedViews.remove(at: index)
    }
}

private extension SectionView {
    @discardableResult
    func _append(_ row: RowView) -> RowView {
        return _append(row.orderedViews)
    }

    @discardableResult
    func _append(_ orderedViews: [UIView]) -> RowView {
        return _addRow(with: orderedViews) { $0.append($1) }
    }

    func _addRow(with views: [UIView], positionRowView: (SubviewOrderable, UIView) -> ()) -> RowView {
        let sectionRow = RowView(views)
        positionRowView(self, sectionRow)
        return sectionRow
    }
}
