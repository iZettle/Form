//
//  FormView.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-10-22.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A view vertically stacking sections views (typically `SectionView`'s) based on a `DynamicFormStyle`.
public class FormView: UIStackView, DynamicStylable {
    public var dynamicStyle: DynamicFormStyle { didSet { applyStyling() } }

    public init(sections: [UIView] = [], style: DynamicFormStyle = .default) {
        self.dynamicStyle = style
        super.init(frame: .zero)
        sections.forEach(addArrangedSubview)
        axis = .vertical
        distribution = .fill
        alignment = .fill

        applyStylingIfNeeded()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func applyStyle(_ style: FormStyle) {
        edgeInsets = style.insets
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyStylingIfNeeded()
    }
}

public extension FormView {
    var sections: [SectionView] {
        return orderedViews.compactMap { $0 as? SectionView }
    }

    @discardableResult
    func appendSection(header: DisplayableString? = nil, footer: DisplayableString? = nil, style: DynamicSectionStyle = .default) -> SectionView {
        return append(SectionView(header: header, footer: footer, style: style))
    }

    @discardableResult
    func appendSection(headerView: UIView?, footerView: UIView?, style: DynamicSectionStyle = .default) -> SectionView {
        return append(SectionView(style: style, headerView: headerView, footerView: footerView))
    }
}

private extension FormView {
    @discardableResult
    func append(_ section: SectionView) -> SectionView {
        orderedViews.append(section)
        return section
    }
}
