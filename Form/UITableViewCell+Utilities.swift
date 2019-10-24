//
//  UITableViewCell+Utilities.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-02.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UITableViewCell {
    /// Create a new instance with an embedded `row` and `style`.
    convenience init(row: RowView, reuseIdentifier: String, style: DynamicTableViewFormStyle = .default) {
        self.init(view: UIStackView(items: row.orderedViews), reuseIdentifier: reuseIdentifier, style: style)
    }

    /// Create a new instance with an embedded `view` and `style`.
    convenience init(view: UIView, reuseIdentifier: String, style: DynamicTableViewFormStyle) {
        self.init(style: .default, reuseIdentifier: reuseIdentifier)

        let left: NSLayoutConstraint = view.leftAnchor == contentView.leftAnchor
        let right: NSLayoutConstraint = view.rightAnchor == contentView.rightAnchor
        let top: NSLayoutConstraint = view.topAnchor == contentView.topAnchor
        let bottom: NSLayoutConstraint = view.bottomAnchor == contentView.bottomAnchor

        func updateInsets(insets: UIEdgeInsets) {
            left.constant = insets.left
            right.constant = -insets.right
            top.constant = insets.top
            bottom.constant = -insets.bottom
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        activate(left, right, top, bottom)

        backgroundColor = .clear
        selectedBackgroundView = UIView(color: .clear)

        let heightConstraint = view.heightAnchor >= 0
        activate(heightConstraint)

        let bag = DisposeBag()
        setAssociatedValue((view, heightConstraint, bag, updateInsets), forKey: &tableFormKey)

        // Getting signal from contentView instead of self to avoid retain cycle between self and bag
        bag += contentView.traitCollectionWithFallbackSignal.distinct().atOnce().with(weak: self as UITableViewCell).onValue { traits, `self` in
            let style = style.style(from: traits)
            self.applyFormStyle(style)
        }
    }
}

public extension UITableView {
    /// Dequeues (reuses) or creates a new cell with the style `style`.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to `#function`.
    func dequeueCell(style: UITableViewCell.CellStyle = .default, reuseIdentifier: String = #function) -> UITableViewCell {
        return dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: style, reuseIdentifier: reuseIdentifier)
    }

    /// Dequeues (reuse) or creates a new cell from `item` and by using the `cellAndConfigure` closure to create and configure the cell.
    /// - Parameter item: The item used to configure the cell.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to name of `Item`'s type.
    /// - Parameter cellAndConfigure: Closure when given a reuse identifier returns a tuple of a `Row` and a configure closure. `
    ///     The configure closure passes the item to be used to configure the cell.
    ///     The disposable returned from the configure closure will be disposed before reusage.
    func dequeueCell<Item, Cell: UITableViewCell>(forItem item: Item, reuseIdentifier: String = String(describing: Item.self), cellAndConfigure: (String) -> (Cell, (Item) -> Disposable)) -> Cell {
        return dequeueCell(forItem: item, reuseIdentifier: reuseIdentifier, cellAndReconfigure: { reuseIdentifier in
            let (cell, configure) = cellAndConfigure(reuseIdentifier)
            return (cell, { _, item in configure(item) })
        })
    }

    /// Dequeues (reuse) or creates a new cell from `item` and by using the `cellAndReconfigure` closure to create and reconfigure  the cell.
    /// - Parameter item: The item used to configure the cell.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to name of `Item`'s type.
    /// - Parameter cellAndReconfigure: Closure when given a reuse identifier returns a tuple of a `Row` and a reconfigure closure. `
    ///     The configure closure passes the passes preceding (if any) and current item to be used to configure the cell.
    ///     The disposable returned from the reconfigure closure will be disposed before reusage.
    func dequeueCell<Item, Cell: UITableViewCell>(forItem item: Item, reuseIdentifier: String = String(describing: Item.self), cellAndReconfigure: (String) -> (Cell, (Item?, Item) -> Disposable), _ noTrailingClosure: Void = ()) -> Cell {
        if let cell = dequeueReusableCell(withIdentifier: reuseIdentifier) as? Cell {
            let (reconfigure, bag) = cell.reconfigureAndBag(Item.self)!
            bag.dispose() // Reuse
            bag += reconfigure(nil, item)
            return cell
        } else {
            let (cell, reconfigure) = cellAndReconfigure(reuseIdentifier)
            let bag = DisposeBag()
            cell.setReconfigureAndBag((reconfigure, bag))
            bag += reconfigure(nil, item)
            return cell
        }
    }

    /// Dequeues (reuses) or creates a new styled cell and using the `item`'s conformance to `Reusable` to create and configure the view to embed in the returned cell.
    func dequeueCell<Item: Reusable>(forItem item: Item, style: DynamicTableViewFormStyle = .default) -> UITableViewCell where Item.ReuseType: ViewRepresentable {
        return dequeueCell(forItem: item, reuseIdentifier: item.reuseIdentifier, cellAndReconfigure: { reuseIdentifier in
            let (viewRepresentable, reconfigure) = Item.makeAndReconfigure()
            return (UITableViewCell(view: viewRepresentable.viewRepresentation, reuseIdentifier: reuseIdentifier, style: style), reconfigure)
        })
    }
}

public extension UITableViewCell {
    func applyFormStyle(_ style: TableViewFormStyle) {

        contentView.backgroundColor = .clear

        (backgroundView as? CellBackgroundView)?.applyStyle(style)
        (selectedBackgroundView as? CellBackgroundView)?.applyStyle(style)

        // Workaround for the reorder icon
        let reorderViewTag = 473659834
        if let reorderControlView = reorderControlView {
            let resizedGripView = viewWithTag(reorderViewTag) ?? TapThroughView()
            resizedGripView.transform = .identity
            resizedGripView.frame = bounds
            resizedGripView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            resizedGripView.backgroundColor = .clear
            resizedGripView.tag = reorderViewTag
            resizedGripView.addSubview(reorderControlView)
            addSubview(resizedGripView)
        }

        if let resizedGripView = viewWithTag(reorderViewTag) {
            resizedGripView.transform = CGAffineTransform(translationX: -style.form.insets.right, y: 0)
        }

        guard let (embeddedView, heightConstraint, _, updateInsets) = (associatedValue(forKey: &tableFormKey) as (UIView, NSLayoutConstraint, DisposeBag, (UIEdgeInsets) -> ())?) else {
            return
        }

        heightConstraint.constant = style.section.minRowHeight

        var insets = style.form.insets
        insets.top = 0
        insets.bottom = 0
        updateInsets(insets)

        if let row = embeddedView as? SectionRowStylable {
            row.apply(rowInsets: style.section.rowInsets, itemSpacing: style.section.itemSpacing)
        }

        if let stack = embeddedView as? UIStackView {
            stack.edgeInsets = style.section.rowInsets
            stack.spacing = style.section.itemSpacing
        }
    }
}

extension UITableViewCell {
    var reorderControlView: UIView? {
        for view in subviews as [UIView] {
            if type(of: view).description() == "UITableViewCellReorderControl" {
                return view
            }
        }
        return nil
    }
}

extension UITableViewCell {
    func updateBackground(forStyle style: DynamicTableViewFormStyle, tableView: UITableView, at indexPath: IndexPath) {
        let position = tableView.position(at: indexPath)
        updateBackground(forStyle: style, position: position)
    }
}

extension UITableViewCell {
    func reconfigure<Item>(old: Item?, new: Item) {
        guard let (reconfigure, bag) = reconfigureAndBag(Item.self) else { return }
        bag.dispose()
        bag += reconfigure(old, new)
    }

    func releaseBag<Item>(forType: Item.Type) {
        guard let (_, bag) = reconfigureAndBag(Item.self) else { return }
        bag.dispose()
    }

    func updateBackground(forStyle style: DynamicTableViewFormStyle, position: CellPosition) {
        guard let backgroundView = backgroundView as? CellBackgroundView, let selectedBackgroundView = selectedBackgroundView as? CellBackgroundView else {
            self.backgroundView = CellBackgroundView(frame: bounds, style: style, position: position)
            self.selectedBackgroundView = CellBackgroundView(frame: bounds, style: style, position: position, forSelection: true)
            return
        }
        backgroundView.position = position
        selectedBackgroundView.position = position
    }

    func updatePosition(position: CellPosition) {
        (backgroundView as? CellBackgroundView)?.position = position
        (selectedBackgroundView as? CellBackgroundView)?.position = position
    }
}

private extension UITableViewCell {
    func reconfigureAndBag<Item>(_ type: Item.Type) -> ((Item?, Item) -> Disposable, DisposeBag)? {
        return associatedValue(forKey: &configureKey)
    }

    func setReconfigureAndBag<Item>(_ configureAndBag: ((Item?, Item) -> Disposable, DisposeBag)) {
        setAssociatedValue(configureAndBag, forKey: &configureKey)
    }
}

// Passing through touches if the touch doesn't hit a subview
private class TapThroughView: UIView {
    fileprivate override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if subview.point(inside: convert(point, to: subview), with: event) { return true }
        }
        return false
    }
}

private class CellBackgroundView: UIView, DynamicStylable {
    let forSelection: Bool
    let backgrounImageView = UIImageView()
    var cachedStyle: TableViewFormStyle?

    lazy var left: NSLayoutConstraint = backgrounImageView.leftAnchor == leftAnchor
    lazy var right: NSLayoutConstraint = backgrounImageView.rightAnchor == rightAnchor

    var dynamicStyle: DynamicTableViewFormStyle

    var position: CellPosition {
        didSet {
            guard position != oldValue else { return }
            updateForNewPosition()
        }
    }

    init(frame: CGRect, style: DynamicTableViewFormStyle, position: CellPosition, forSelection: Bool = false) {
        self.dynamicStyle = style
        self.position = position
        self.forSelection = forSelection

        super.init(frame: frame)

        self.backgroundColor = .clear
        self.backgrounImageView.contentMode = .scaleToFill

        backgrounImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(backgrounImageView)
        activate(left, right, backgrounImageView.topAnchor == topAnchor, backgrounImageView.bottomAnchor == bottomAnchor)
        applyStylingIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyStylingIfNeeded()
    }

    func updateForNewPosition() {
        guard let style = cachedStyle else {
            return
        }

        let background = forSelection ? style.section.selectedBackground : style.section.background
        backgrounImageView.image = background.image(for: position)
    }

    func applyStyle(_ style: TableViewFormStyle) {
        cachedStyle = style
        updateForNewPosition()

        left.constant = style.form.insets.left
        right.constant = -style.form.insets.right
    }
}

private var configureKey = false
private var tableFormKey = false
