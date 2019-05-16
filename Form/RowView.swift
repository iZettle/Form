//
//  RowView.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-26.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A stack of horizontally ordered views typically used to build rows for adding and presenting in e.g. a `SectionView`.
///
///     let row = RowView(title: "title", subtitle: "subtitle").append(.chevron)
///     section.append(row).onValue { /* row tapped */ }
public final class RowView: UIStackView {
    /// The label for the title when `self` was constructed with a title.
    public let titleLabel: UILabel?

    /// The label for the subtitle when `self` was constructed with a subtitle.
    public let subtitleLabel: UILabel?

    init(_ views: [UIView], titleLabel: UILabel? = nil, subtitleLabel: UILabel? = nil) {
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel

        super.init(frame: CGRect.zero)

        views.forEach(addArrangedSubview)
        distribution = .fill
        alignment = .center
        axis = .horizontal
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension RowView {
    convenience init(_ views: UIView...) {
        self.init(views)
    }
}

public extension RowView {
    /// Creates new instance with a title
    /// - Parameters:
    ///    - appendSpacer: Whether a `.spacer` we should be appended to move succeeding views to the right. Defaults to true.
    convenience init(title: DisplayableString, style: TextStyle = TitleSubtitleStyle.default.title, appendSpacer: Bool = true) {
        let titleSubtitleStyle = TitleSubtitleStyle.default.restyled { $0.title = style }
        self.init(title: title, subtitle: "", style: titleSubtitleStyle, appendSpacer: appendSpacer)
    }

    /// Creates new instance with a stackview show a title at the top and subtile at the bottom
    /// - Parameters:
    ///    - appendSpacer: Whether a `.spacer` we should be appended to move succeeding views to the right. Defaults to true.
    convenience init(title: DisplayableString, subtitle: DisplayableString, style: TitleSubtitleStyle = .default, appendSpacer: Bool = true) {
        var titleLabel: UILabel!
        var subtitleLabel: UILabel!

        let stack = UIStackView(title: title, subtitle: subtitle, style: style) { title, subtitle in
            titleLabel = title
            subtitleLabel = subtitle
        }
        self.init([stack] + (appendSpacer ? [.spacer] : []), titleLabel: titleLabel, subtitleLabel: subtitleLabel)
    }

    /// Access to the `titleLabel`s value when `self` was constructed with a title.
    var title: DisplayableString? {
        get { return titleLabel?.value }
        set { titleLabel?.value = newValue ?? "" }
    }

    /// Access to the `subtitleLabel`s value when `self` was constructed with a subtitle.
    var subtitle: DisplayableString? {
        get { return subtitleLabel?.value }
        set { subtitleLabel?.value = newValue ?? "" }
    }
}

public extension RowView {
    /// Appends `view` and returns `self` and `view` in a `RowAndProvider`.
    /// - Note: If you run into ambiguities or don't want use this overload casting to `UIView` such as `append(control as UIView)`
    @discardableResult
    func append<View: UIView & SignalProvider>(_ view: View) -> RowAndProvider<View> {
        append(view as UIView)
        return RowAndProvider(row: self, provider: view)
    }

    /// Prepends `view` and returns `self` and `view` in a `RowAndProvider`.
    /// - Note: If you run into ambiguities or don't want use this overload casting to `UIView` such as `append(control as UIView)`
    @discardableResult
    func prepend<View: UIView & SignalProvider>(_ view: View) -> RowAndProvider<View> {
        prepend(view as UIView)
        return RowAndProvider(row: self, provider: view)
    }
}

extension RowView: SectionRowStylable {
    public func apply(rowInsets: UIEdgeInsets, itemSpacing: CGFloat) {
        edgeInsets = rowInsets
        spacing = itemSpacing
    }
}
