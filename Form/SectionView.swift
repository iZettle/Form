//
//  SectionView.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-10-22.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A view vertically stacking and laying out row views based on a `DynamicSectionStyle`.
/// Self can also contain a header before the rows and a footer after them.
public class SectionView: UIView {
    private let header: HeaderFooterView
    private var rowsStackView: UIStackView
    private var footer: HeaderFooterView
    private typealias Row = (select: SelectView, content: UIView, background: UIImageView, selected: UIImageView)
    private var rows = [Row]()
    private let hiddenBag = DisposeBag()
    private let rowsLayoutArea: ViewLayoutArea
    private var rowConstraints: [NSLayoutConstraint] = []
    private let oneAtTheTimeHiddenUpdate = SingleTaskPerformer<()>()

    public var dynamicStyle: DynamicSectionStyle {
        didSet { applyStyling() }
    }

    public init(rows: [UIView] = [], rowsLayoutArea: ViewLayoutArea = .default, style: DynamicSectionStyle = .default, headerView: UIView?, footerView: UIView?) {
        self.dynamicStyle = style
        self.header = HeaderFooterView(view: headerView)
        self.footer = HeaderFooterView(view: footerView)
        rowsStackView = UIStackView(views: [], axis: .vertical)
        self.rowsLayoutArea = rowsLayoutArea

        var views = [UIView?]()
        views.append(self.header)
        views.append(rowsStackView)
        views.append(self.footer)
        super.init(frame: CGRect.zero)
        clipsToBounds = true

        let stackView = UIStackView(views: views.compactMap { $0 }, axis: .vertical)
        embedView(stackView)

        self.updateOrderedViews(to: rows)
        orderedViews = rows
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyStylingIfNeeded()
    }
}

/// Conforming types can have a rowInsets and itemSpacing applied to them.
/// Used by e.g. `SectionView` to apply its row styling to its rows.
public protocol SectionRowStylable: class {
    func apply(rowInsets: UIEdgeInsets, itemSpacing: CGFloat)
}

public extension SectionView {
    convenience init(rows: [UIView] = [], rowsLayoutArea: ViewLayoutArea = .default, header: DisplayableString? = nil, footer: DisplayableString? = nil, style: DynamicSectionStyle = .default) {
        let headerView: UIView? = header.map { UILabel(value: $0) }
        let footerView: UIView? = footer.map { UILabel(value: $0) }
        self.init(rows: rows, rowsLayoutArea: rowsLayoutArea, style: style, headerView: headerView, footerView: footerView)
    }
}

extension SectionView: SubviewOrderable {
    public var orderedViews: [UIView] {
        get { return rows.map { $0.content } }
        set {
            updateOrderedViews(to: newValue)
            applyStyling()
        }
    }
}

public extension SectionView {
    var headerView: UIView? {
        return header.view
    }

    /// Returns the headerView if it's set and is a UILabel or subclass thereof.
    var headerLabel: UILabel? {
        return headerView as? UILabel
    }

    var footerView: UIView? {
        return footer.view
    }

    /// Returns the footerView if it's set and is a UILabel or subclass thereof.
    var footerLabel: UILabel? {
        return footerView as? UILabel
    }

    /// Returns a signal for observing selection of the row which `view` belongs to.
    func selectSignal(for view: UIView) -> Signal<()>? {
        return selectView(for: view)?.providedSignal
    }

    /// Returns a signal for updating and observing the isSelected state of the row which `view` belongs to.
    func isSelectedSignal(for view: UIView) -> ReadWriteSignal<Bool>? {
        return selectView(for: view)?.isSelectedSignal
    }

    /// Returns a signal for updating and observing the isHighlighted state of the row which `view` belongs to.
    func isHighlightedSignal(for view: UIView) -> ReadWriteSignal<Bool>? {
        return selectView(for: view)?.isHighlightedSignal
    }
}

extension SectionView: DynamicStylable {
    public func applyStyle(_ style: SectionStyle) {
        let rowsAndConstraints = zip(rows, rowConstraints).filter { !$0.0.content.isHidden }
        let visibleRowsCount = rowsAndConstraints.count

        for (i, (row, rowConstraint)) in rowsAndConstraints.enumerated() {
            rowConstraint.constant = style.minRowHeight
            let isFirst = i == 0
            let isLast = i == visibleRowsCount - 1
            let position = CellPosition(isFirst: isFirst, isLast: isLast)
            row.background.image = style.background.image(for: position)
            row.selected.image = style.selectedBackground.image(for: position)

            if let row = row.content as? SectionRowStylable {
                row.apply(rowInsets: style.rowInsets, itemSpacing: style.itemSpacing)
            }
        }

        header.applyStyle(style.header)
        footer.applyStyle(style.footer)
    }
}

private extension SectionView {
    func selectView(for view: UIView) -> SelectView? {
        return rows.firstIndex { $0.content == view }.map { rows[$0] }?.select
    }

    final class HeaderFooterView: UIView {
        let imageView = UIImageView()
        let view: UIView?
        let stackView: UIStackView?
        var heightConstraint: NSLayoutConstraint?

        init(view: UIView?) {
            self.view = view
            stackView = view.map { UIStackView(arrangedSubviews: [ $0 ]) }
            super.init(frame: .zero)
            embedView(imageView)
            if let stackView = stackView {
                embedView(stackView)
            } else {
                heightConstraint = heightAnchor == 0
                activate(heightConstraint!)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func applyStyle(_ style: HeaderFooterStyle) {
            stackView?.edgeInsets = style.insets
            heightConstraint?.constant = style.emptyHeight
            imageView.image = style.backgroundImage
            if let label = view as? UILabel {
                label.style = style.text
            }
        }
    }

    func updateOrderedViews(to newValue: [UIView]) {
        let stack = rowsStackView
        for change in orderedViews.changes(toBuild: newValue) {
            switch change {
            case let .insert(view, index):
                insert(view: view, at: index, in: stack)
            case let .delete(_, index):
                removeView(at: index, from: stack)
            case let .move(view, oldIndex, newIndex):
                removeView(at: oldIndex, from: stack)
                insert(view: view, at: newIndex, in: stack)
            case let .update(view, index):
                stack.orderedViews[index] = view
            }
        }

        hiddenBag.dispose()

        var synchronizedHides = [(() -> ())]()

        for row in rows {
            hiddenBag += row.content.signal(for: \.isHidden).onValue { [weak self] hidden in
                guard let `self` = self else { return }

                let action = {
                    row.select.isHidden = hidden
                    self.applyStyling()
                }

                // Make sure to run hidden animations if several in the same animation to fix animation bugs.
                isInAnimationBlock().onValue { isAnimating in
                    if isAnimating {
                        synchronizedHides.append(action)
                        self.oneAtTheTimeHiddenUpdate.coalesceToNextRunLoop {
                            UIView.animate(withDuration: 0.3) {
                                synchronizedHides.forEach { $0(); self.applyStyling() }
                                synchronizedHides.removeAll()
                            }
                        }
                    } else {
                        action()
                    }
                }
            }

            if let selectable = row.content as? Selectable {
                hiddenBag += selectable.isSelectedSignal.atOnce().bindTo(row.select.isSelectedSignal)
            }
        }
    }

    /// Inserts a view at a given index in a given `UIStackView`
    func insert(view: UIView, at index: Int, `in` stackView: UIStackView) {
        let background = UIImageView()
        let selected = UIImageView()
        let select = SelectView(embeddedView: view, withinLayoutArea: rowsLayoutArea, backgroundView: background, selectedBackgroundView: selected)
        let row: Row = (select, view, background, selected)
        rows.insert(row, at: index)

        stackView.orderedViews.insert(select, at: index)
        let constraint = view.heightAnchor >= 0
        rowConstraints.insert(constraint, at: index)
        activate(constraint)
    }

    /// Removes a view from a given index from a given `UIStackView`
    func removeView(at index: Int, from stackView: UIStackView) {
        rows.remove(at: index)
        stackView.orderedViews.remove(at: index)
        let constraint = rowConstraints.remove(at: index)
        deactivate(constraint)
    }
}

/// Will complete with true the function when called was in an animation block.
private func isInAnimationBlock() -> Future<Bool> {
    return Future { completion in
        guard UIView.areAnimationsEnabled else {
            completion(.success(false))
            return NilDisposer()
        }
        let delegate = AnimationDelegate {
            completion(.success($0))
        }
        UIView.setAnimationDelegate(delegate)
        UIView.setAnimationDidStop(#selector(AnimationDelegate.didStop))
        delegate.perform(#selector(AnimationDelegate.didNotStop), with: nil, afterDelay: 0)
        return Disposer {
            NSObject.cancelPreviousPerformRequests(withTarget: delegate)
        }
    }
}

private class AnimationDelegate: NSObject {
    var completion: ((Bool) -> ())?
    init(completion: @escaping (Bool) -> ()) { self.completion = completion }
    @objc func didStop() { completion?(true); completion = nil }
    @objc func didNotStop() { completion?(false); completion = nil }
}
