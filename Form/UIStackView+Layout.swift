//
//  UIStackView+Layout.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-10-14.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public extension UIStackView {
    convenience init(views: [ViewRepresentable], axis: NSLayoutConstraint.Axis = .horizontal, spacing: CGFloat = 0, edgeInsets: UIEdgeInsets = .zero) {
        self.init(arrangedSubviews: views.map { $0.viewRepresentation })
        self.spacing = spacing
        self.axis = axis
        self.edgeInsets = edgeInsets
    }

    convenience init(rows: [ViewRepresentable], spacing: CGFloat = 0, edgeInsets: UIEdgeInsets = .zero) {
        self.init(views: rows, axis: .vertical, spacing: spacing, edgeInsets: edgeInsets)
    }

    convenience init(columns: [ViewRepresentable], spacing: CGFloat = 0, edgeInsets: UIEdgeInsets = .zero) {
        self.init(views: columns, axis: .horizontal, spacing: spacing, edgeInsets: edgeInsets)
        distribution = .fill
        alignment = .center
    }

    convenience init(items: [ViewRepresentable]) {
        self.init(columns: items, spacing: 10)
    }

    convenience init(row: RowView) {
        self.init(items: row.orderedViews)
    }
}

public extension UIStackView {
    convenience init(title: UILabel, subtitle: UILabel) {
        self.init(rows: [title, subtitle])
        alignment = .leading
        distribution = .equalSpacing
    }

    convenience init(title: DisplayableString, subtitle: DisplayableString, style: TitleSubtitleStyle = .default, configure: (_ titleLabel: UILabel, _ subtitleLabel: UILabel) -> () = { _, _  in }) {
        let titleLabel = UILabel(value: title, style: style.title)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let subtitleLabel = UILabel(value: subtitle, style: style.subtitle)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        configure(titleLabel, subtitleLabel)
        self.init(title: titleLabel, subtitle: subtitleLabel)

        self.spacing = style.spacing
        self.edgeInsets = style.insets
    }
}

public extension UIStackView {
    var edgeInsets: UIEdgeInsets {
        get {
            return isLayoutMarginsRelativeArrangement ? layoutMargins : .zero
        }
        set {
            isLayoutMarginsRelativeArrangement = newValue != .zero
            if #available(iOS 11, *) {
                insetsLayoutMarginsFromSafeArea = false
            }
            if isLayoutMarginsRelativeArrangement {
                layoutMargins = newValue
            }
        }
    }
}

extension UIStackView: SubviewOrderable {
    public var orderedViews: [UIView] {
        get { return arrangedSubviews }
        set {
            for change in arrangedSubviews.changes(toBuild: newValue) {
                switch change {
                case let .insert(view, index):
                    insertArrangedSubview(view, at: index)
                case let .delete(view, _):
                    removeArrangedSubview(view)
                    view.removeFromSuperview()
                case let .move(view, _, newIndex):
                    removeArrangedSubview(view)
                    view.removeFromSuperview()
                    insertArrangedSubview(view, at: newIndex)
                case let .update(view, index):
                    removeArrangedSubview(view)
                    view.removeFromSuperview()
                    insertArrangedSubview(view, at: index)
                }
            }
        }
    }
}
