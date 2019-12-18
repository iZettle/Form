//
//  SectionStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-10-22.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public struct SectionStyle: Style {
    /// Insets used for rows.
    /// - Note: Requires views to conform to SectionRowStylable
    public var rowInsets: UIEdgeInsets

    /// Spacing bettwen row items.
    /// - Note: Requires views to conform to SectionRowStylable
    public var itemSpacing: CGFloat

    /// The minimum hight of a row.
    public var minRowHeight: CGFloat

    /// Row background.
    public var background: Background

    /// Selected row background.
    public var selectedBackground: Background

    public var header: HeaderFooterStyle
    public var footer: HeaderFooterStyle

    public init(rowInsets: UIEdgeInsets, itemSpacing: CGFloat, minRowHeight: CGFloat,
                background: Background, selectedBackground: Background,
                header: HeaderFooterStyle, footer: HeaderFooterStyle) {
        self.rowInsets = rowInsets
        self.itemSpacing = itemSpacing
        self.minRowHeight = minRowHeight
        self.background = background
        self.selectedBackground = selectedBackground
        self.header = header
        self.footer = footer
    }
}

public extension SectionStyle {
    /// Images to use for section row backgrounds depending of position within section.
    struct Background {
        public var top: UIImage?
        public var middle: UIImage?
        public var bottom: UIImage?
        public var unique: UIImage?
    }
}

public struct DynamicSectionStyle: DynamicStyle {
    public var styleGenerator: (UITraitCollection) -> SectionStyle
    public init(generateStyle : @escaping (UITraitCollection) -> SectionStyle) {
        self.styleGenerator = generateStyle
    }
}

public extension DynamicSectionStyle {
    static let systemGrouped = DynamicSectionStyle { Style(traits: $0, isGrouped: true) }
    static let systemPlain = DynamicSectionStyle { Style(traits: $0, isGrouped: false) }

    static var defaultGrouped: DynamicSectionStyle { return DefaultStyling.current.sectionGrouped }
    static var defaultPlain: DynamicSectionStyle { return DefaultStyling.current.sectionPlain }

    static var `default`: DynamicSectionStyle { return defaultGrouped }
}

public extension DynamicSectionStyle {
    /// Returns a restyled instance with an opened top background and header removed.
    /// - Note: See `SectionStyle.Background.openTop()`
    var openedTop: DynamicSectionStyle {
        return headerRemoved.restyled { style in
            style.background.openTop()
            style.selectedBackground.openTop()
        }
    }

    /// Returns a restyled instance with an opened bottom background and footer removed.
    /// - Note: See `SectionStyle.Background.openBottom()`
    var openedBottom: DynamicSectionStyle {
        return footerRemoved.restyled { style in
            style.background.openBottom()
            style.selectedBackground.openBottom()
            style.footer = .none
        }
    }

    /// Returns a restyled instance with a header set to `.none`.
    var headerRemoved: DynamicSectionStyle {
        return restyled { $0.header = .none }
    }

    /// Returns a restyled instance with a footer set to `.none`.
    var footerRemoved: DynamicSectionStyle {
        return restyled { $0.footer = .none }
    }
}

public extension SectionStyle.Background {
    init(all: UIImage?) {
        top = all
        middle = all
        bottom = all
        unique = all
    }

    init(style: SectionBackgroundStyle) {
        top = SegmentBackgroundStyle(style: style, position: .top)?.image()
        middle = SegmentBackgroundStyle(style: style, position: .middle)?.image()
        bottom = SegmentBackgroundStyle(style: style, position: .bottom)?.image()
        unique = SegmentBackgroundStyle(style: style, position: .unique)?.image()
    }
}

public extension SectionStyle.Background {
    static let none = SectionStyle.Background(style: .none)

    static let system = SectionStyle.Background(style: .system)
    static let systemSelected = SectionStyle.Background(style: .systemSelected)

    static let systemInsetted = SectionStyle.Background(style: .systemInsetted)
    static let systemInsettedSelected = SectionStyle.Background(style: .systemInsettedSelected)

    static let `default` = SectionStyle.Background(style: SectionBackgroundStyle.default)
}

public extension SectionStyle.Background {
    /// Opens top by setting `top` to `middle` and `unique` to `bottom`.
    mutating func openTop() {
        self.top = middle
        self.unique = bottom
    }

    /// Opens bottom by setting `bottom` to `middle` and `unique` to `top`.
    mutating func openBottom() {
        self.bottom = middle
        self.unique = top
    }
}

private extension SectionStyle {
    init(traits: UITraitCollection, isGrouped: Bool) {
        minRowHeight = 44
        rowInsets = UIEdgeInsets(horizontalInset: 15, verticalInset: 9)
        itemSpacing = 10

        let insetted = isGrouped && traits.horizontalSizeClass == .regular
        background = insetted ? .systemInsetted : .system
        selectedBackground = insetted ? .systemInsettedSelected : .systemSelected

        if isGrouped {
            let headerInsets = UIEdgeInsets(top: .halfSectionSpacing, left: rowInsets.left, bottom: 6, right: rowInsets.right)
            let backgroundImage = SectionStyle.Background.none.top
            header = HeaderFooterStyle(text: .headerTextStyle, backgroundImage: backgroundImage, insets: headerInsets, emptyHeight: .halfSectionSpacing)

            let footerInsets = UIEdgeInsets(top: 6, left: rowInsets.left, bottom: .halfSectionSpacing, right: rowInsets.right)

            let footerBackgroundImage = SectionStyle.Background.none.bottom
            footer = HeaderFooterStyle(text: .footerTextStyle, backgroundImage: footerBackgroundImage, insets: footerInsets, emptyHeight: .halfSectionSpacing)
        } else {
            let text = TextStyle.headerFooterTextStyle.restyled { $0.font = .boldSystemFont(ofSize: 17) }
            let insets = UIEdgeInsets(top: 0, left: rowInsets.left, bottom: 4, right: rowInsets.right)

            header = HeaderFooterStyle(text: text, backgroundImage: .plainHeaderFooter, insets: insets)
            footer = HeaderFooterStyle(text: text, backgroundImage: .plainHeaderFooter, insets: insets)
        }
    }
}

extension SectionStyle.Background {
    func image(for position: CellPosition) -> UIImage? {
        switch position {
        case .top: return top
        case .bottom: return bottom
        case .middle: return middle
        case .unique: return unique
        }
    }
}

private extension TextStyle {
    static let headerFooterTextStyle = TextStyle(font: .systemFont(ofSize: 13), color: UIColor(red: 0.43, green: 0.43, blue: 0.45, alpha: 1), alignment: .left)
    static let headerTextStyle = headerFooterTextStyle.uppercased
    static let footerTextStyle = headerFooterTextStyle
}

private extension BackgroundStyle {
    static let plainHeaderFooter = BackgroundStyle(color: UIColor(white: 0.97, alpha: 1), border: .none)
}

private extension UIImage {
    @nonobjc static let plainHeaderFooter: UIImage? = SegmentBackgroundStyle(style: .plainHeaderFooter)?.image()
}

private extension CGFloat {
    static let sectionSpacing: CGFloat = 30
    static let halfSectionSpacing = sectionSpacing/2
}

let prototypeGroupedTableView = UITableView(frame: .zero, style: .grouped)
