//
//  TableViewFormStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-10-25.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit

public struct TableViewFormStyle: Style {
    public var section: SectionStyle
    public var form: FormStyle

    /// Whether or not row, header and footer should use fixed instead of dynamic heights.
    public var fixedRowHeight: CGFloat?
    public var fixedHeaderHeight: CGFloat?
    public var fixedFooterHeight: CGFloat?
}

public extension DynamicTableViewFormStyle {
    /// Returns the currently used form style.
    var form: DynamicFormStyle {
        return DynamicFormStyle { self.style(from: $0).form }
    }

    /// Returns the currently used section style.
    var section: DynamicSectionStyle {
        return DynamicSectionStyle { self.style(from: $0).section }
    }

    /// Returns the currently used section header style.
    var header: DynamicHeaderFooterStyle {
        return DynamicHeaderFooterStyle { self.style(from: $0).section.header }
    }

    /// Returns the currently used section footer style.
    var footer: DynamicHeaderFooterStyle {
        return DynamicHeaderFooterStyle { self.style(from: $0).section.footer }
    }
}

public struct DynamicTableViewFormStyle: DynamicStyle {
    public var tableStyle: UITableView.Style
    public var styleGenerator: (UITraitCollection) -> TableViewFormStyle
}

public extension DynamicTableViewFormStyle {
    init(section: @autoclosure @escaping () -> DynamicSectionStyle, form: @autoclosure @escaping () -> DynamicFormStyle, tableStyle: UITableView.Style = .grouped, fixedRowHeight: CGFloat? = nil, fixedHeaderHeight: CGFloat? = nil, fixedFooterHeight: CGFloat? = nil) {
        self.tableStyle = tableStyle
        styleGenerator = { (styleInput: UITraitCollection) in
            return TableViewFormStyle(section: section().style(from: styleInput), form: form().style(from: styleInput), fixedRowHeight: fixedRowHeight, fixedHeaderHeight: fixedRowHeight, fixedFooterHeight: fixedFooterHeight)
        }
    }
}

public extension DynamicTableViewFormStyle {
    static var plain: DynamicTableViewFormStyle {
        return .init(section: .defaultPlain, form: .defaultPlain, tableStyle: .plain)
    }

    static var grouped: DynamicTableViewFormStyle {
        return .init(section: .defaultGrouped, form: .defaultGrouped, tableStyle: .grouped)
    }

    static let `default` = DynamicTableViewFormStyle.grouped
}

public extension DynamicTableViewFormStyle {
    /// Returns a restyled instance with an opened top background and header removed.
    /// - Note: See `SectionStyle.Background.openTop()`
    var openedTop: DynamicTableViewFormStyle {
        return headerRemoved.restyled { style in
            style.section.background.openTop()
            style.section.selectedBackground.openTop()
            style.form.insets.top = 0
        }
    }

    /// Returns a restyled instance with an opened bottom background and footer removed.
    /// - Note: See `SectionStyle.Background.openBottom()`
    var openedBottom: DynamicTableViewFormStyle {
        return footerRemoved.restyled { style in
            style.section.background.openBottom()
            style.section.selectedBackground.openBottom()
            style.form.insets.bottom = 0
        }
    }

    /// Returns a restyled instance with a section header set to `.none` and `fixedHeaderHeight` set to 0.
    var headerRemoved: DynamicTableViewFormStyle {
        return restyled { style in
            style.fixedHeaderHeight = 0
            style.section.header = .none
        }
    }

    /// Returns a restyled instance with a section footer set to `.none` and `fixedFooterHeight` set to 0.
    var footerRemoved: DynamicTableViewFormStyle {
        return restyled { style in
            style.fixedFooterHeight = 0
            style.section.footer = .none
        }
    }
}
