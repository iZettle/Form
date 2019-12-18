//
//  CustomStyle.swift
//  Example
//
//  Created by Måns Bernhardt on 2018-06-11.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Form

extension DefaultStyling {
    static func installCustom() {
        ListTableView.self.appearance().backgroundColor = .modalFormBackground

        for view in [FormScrollView.self, FormTableView.self] {
            view.appearance(for: UITraitCollection(userInterfaceIdiom: .pad)).backgroundColor = .standardFormBackground
            view.appearance().backgroundColor = .modalFormBackground
        }

        UINavigationBar.appearance().tintColor = .mintGreenDark

        current = .custom
    }

    static var custom: DefaultStyling { return DefaultStyling(
        text: .normalText,
        field: FieldStyle(text: .normalText, placeholder: .placeholderText, disabled: .disabledText, cursorColor: .mintGreen),
        detailText: TitleSubtitleStyle.custom.subtitle,
        titleSubtitle: .custom,
        button: .custom,
        barButton: .custom,
        switch: .custom,
        segmentedControl: .custom,
        sectionGrouped: .form,
        sectionPlain: .list,
        formGrouped: .form,
        formPlain: .list,
        sectionBackground: .plain,
        sectionBackgroundSelected: .plainSelected,
        scrollView: FormScrollView.self,
        plainTableView: ListTableView.self,
        groupedTableView: FormTableView.self,
        collectionView: UICollectionView.self
    )}
}

var isRegular: Bool { return UIApplication.shared.keyWindow?.traitCollection.horizontalSizeClass == .regular }

extension UIColor {
    static let backgroundGray = UIColor(hue: 0, saturation: 0, brightness: 0.98, alpha: 1)
    static let backgroundGrayDark = UIColor(hue: 0, saturation: 0, brightness: 0.95, alpha: 1)
    static let lineGray = UIColor(hue: 0, saturation: 0, brightness: 0.83, alpha: 1)
    static let textGray = UIColor(hue: 0, saturation: 0, brightness: 0.65, alpha: 1)
    static let placeholderTextGray = UIColor(hue: 0, saturation: 0, brightness: 0.75, alpha: 1)
    static let disabledTextGray = UIColor(hue: 0, saturation: 0, brightness: 0.60, alpha: 1)

    static let mintGreen = UIColor(hue: 141.0/360, saturation: 0.49, brightness: 0.82, alpha: 1)
    static let mintGreenDark = UIColor(hue: 141.0/360, saturation: 0.56, brightness: 0.75, alpha: 1)
    static let lilacHighlighted = UIColor(hue: 255.0/360, saturation: 0.10, brightness: 1, alpha: 1)
    static let lilacLine = UIColor(hue: 253.0/360, saturation: 0.21, brightness: 0.94, alpha: 1)

    static let standardSectionBackground: UIColor = .white
    static let standardFormBackground: UIColor = .backgroundGrayDark
    static let modalFormBackground: UIColor = .backgroundGray
    static let plainFormBackground: UIColor = .modalFormBackground

    static let plainSelection: UIColor = .lilacHighlighted
    static let modalSelection: UIColor = .lilacHighlighted

    static let separator: UIColor = .lineGray
}

extension UIFont {
    static let normalTextStatic: UIFont = {
        if #available(iOS 10.0, *) {
            return UIFont.preferredFont(
                forTextStyle: .body,
                compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
            )
        } else {
            return UIFont.systemFont(ofSize: 17, weight: .medium)
        }
    }()
    static let normalText = UIFont.preferredFont(forTextStyle: .body)
    static let smallText = UIFont.preferredFont(forTextStyle: .callout)
    static let regularButton = UIFont.preferredFont(forTextStyle: .title3)
    static let headerText = UIFont.preferredFont(forTextStyle: .subheadline)
}

extension TextStyle {
    static let normalText = TextStyle(font: .normalText, color: .black)
    static let placeholderText = TextStyle(font: .normalText, color: .placeholderTextGray)
    static let disabledText = TextStyle(font: .normalText, color: .disabledTextGray)
    static let smallText = TextStyle(font: .smallText, color: .textGray)
    static let regularButton = TextStyle(font: .regularButton, color: .mintGreenDark, alignment: .center)
    static let disabledButton = TextStyle(font: .regularButton, color: .textGray, alignment: .center)
    static let whiteButton = TextStyle(font: .regularButton, color: .white, alignment: .center)
    static let headerText = TextStyle(font: .headerText, color: .textGray).restyled { $0.letterSpacing = 0.8 }.uppercased
    static let footer = smallText.centerAligned.multilined()
    static let headerBlack = headerText.colored(.black).multilined()
    static let header = headerText.multilined()
}

extension TitleSubtitleStyle {
    static let custom = TitleSubtitleStyle(title: TextStyle.normalText.truncatedMiddle, subtitle: TextStyle.smallText.truncatedMiddle, spacing: 0, insets: .zero)
}

extension BorderStyle {
    static let bottomSeparator = BorderStyle(width: UIScreen.main.hairlineWidth, color: .separator, cornerRadius: 0, borderEdges: .bottom)
}

extension ButtonStyle {
    static let custom = ButtonStyle(contentInsets: UIEdgeInsets(horizontalInset: 5, verticalInset: 3),
                                    normal: ButtonStateStyle(color: .clear, border: .none, text: .regularButton),
                                    highlighted: ButtonStateStyle(color: .mintGreen, border: BorderStyle(cornerRadius: 4), text: .whiteButton),
                                    disabled: ButtonStateStyle(color: .clear, border: .none, text: .disabledButton))
}

extension BarButtonStyle {
    static let custom = BarButtonStyle(text: TextStyle.normalText.colored(.mintGreenDark).restyled {
        $0.font = .normalTextStatic
    })
}

extension SwitchStyle {
    public static let custom: SwitchStyle = SwitchStyle(onTintColor: .mintGreen)
}

extension SegmentedControlStyle {

    static let custom = SegmentedControlStyle(
        normal: ButtonStateStyle(color: .white, border: .init(width: UIScreen.main.hairlineWidth, color: .lineGray, cornerRadius: 4), text: TextStyle.normalText.centerAligned.colored(.mintGreen).resized(to: 15)),
        highlighted: ButtonStateStyle(color: .mintGreenDark, border: .init(cornerRadius: 4), text: TextStyle.normalText.centerAligned.colored(.white).resized(to: 15)),
        disabled: ButtonStateStyle(color: .mintGreen, border: .init(cornerRadius: 4), text: TextStyle.normalText.centerAligned.colored(.textGray).resized(to: 15)),
        selected: ButtonStateStyle(color: .mintGreen, border: .init(cornerRadius: 4), text: TextStyle.normalText.centerAligned.colored(.white).resized(to: 15)),
        tintColor: .mintGreen
    )
}

enum FormType {
    case list, form
}

extension FormStyle {
    init(traits: UITraitCollection, type: FormType) {
        switch (type, traits.horizontalSizeClass) {
        case (.list, _), (_, .compact):
            self.init(insets: UIEdgeInsets(top: 22, left: 0, bottom: 0, right: 0))
        case (.form, _):
            self.init(insets: UIEdgeInsets(top: 40, left: 40, bottom: 0, right: 40))
        }
    }
}

extension DynamicFormStyle {
    static let form = DynamicFormStyle { Style(traits: $0, type: .form) }
    static let list = DynamicFormStyle { Style(traits: $0, type: .list) }
}

extension SectionStyle {
    init(traits: UITraitCollection, type: FormType) {
        let rowInsets = UIEdgeInsets(horizontalInset: traits.isRegular ? 18 : 16, verticalInset: traits.isRegular ? 14 : 13)

        let background, selectedBackground: Background
        switch (type, traits.horizontalSizeClass) {
        case (.form, .compact):
            background = .plain
            selectedBackground = .plainSelected
        case (.form, _):
            background = .grouped
            selectedBackground = .groupedSelected
        case (.list, _):
            background = .list
            selectedBackground = .listSelected
        }

        let footerInsets = UIEdgeInsets(top: 10, left: rowInsets.left, bottom: 6 + .standardFooterHeight, right: rowInsets.right)
        let footerStyle = HeaderFooterStyle(text: .footer,
                                            backgroundImage: .plainSectionFooter,
                                            insets: footerInsets,
                                            emptyHeight: .standardFooterHeight)

        let headerInsets = UIEdgeInsets(top: 11, left: rowInsets.left, bottom: 7, right: rowInsets.right)
        let headerStyle = HeaderFooterStyle(text: .headerBlack,
                                            backgroundImage: .plainFormSectionHeader,
                                            insets: headerInsets,
                                            emptyHeight: 0)

        let header, footer: HeaderFooterStyle
        switch (type, traits.horizontalSizeClass) {
        case (.list, _), (_, .unspecified):
            header = headerStyle.restyled {
                $0.text = TextStyle.header.uppercased
                $0.backgroundImage = .plainSectionHeader
            }
            footer = footerStyle
        case (.form, .compact):
            header = headerStyle
            footer = footerStyle
        case (.form, .regular):
            header = headerStyle.restyled {
                $0.insets.top = 0
                $0.backgroundImage = .none
            }
            footer = footerStyle.restyled { $0.backgroundImage = .none }
        default:
            fatalError()
        }

        self.init(rowInsets: rowInsets, itemSpacing: .standardItemSpacing, minRowHeight: .standardRowHeight,
                  background: background, selectedBackground: selectedBackground,
                  header: header, footer: footer)
    }
}

extension DynamicSectionStyle {
    static var form = DynamicSectionStyle { Style(traits: $0, type: .form) }
    static var list = DynamicSectionStyle { Style(traits: $0, type: .list) }
}

extension SectionBackgroundStyle {
    static let plain = SectionBackgroundStyle(background: BackgroundStyle(color: .standardSectionBackground, border: BorderStyle(width: UIScreen.main.hairlineWidth, color: .separator, cornerRadius: 0, borderEdges: [.top, .bottom])),
                                                     topSeparator: .none,
                                                     bottomSeparator: InsettedStyle(style: SeparatorStyle(width: UIScreen.main.hairlineWidth, color: .separator), insets: UIEdgeInsets(horizontalInset: 0, verticalInset: 0)))

    static let plainSelected = SectionBackgroundStyle.plain.restyled { style in
        style.color = .plainSelection
        style.border.color = .lilacLine
        style.bottomSeparator.style.color = .lilacLine
        style.topSeparator = style.bottomSeparator
    }

    static let list = SectionBackgroundStyle.plain.restyled { $0.border.borderEdges = .bottom }
    static let listSelected = SectionBackgroundStyle.plainSelected.restyled { $0.border.borderEdges = .bottom }

    static let grouped = SectionBackgroundStyle.plain.restyled { style in
        style.bottomSeparator.insets = .zero
        style.border = BorderStyle(width: UIScreen.main.hairlineWidth, color: .separator, cornerRadius: 8)
    }

    static let groupedSelected = SectionBackgroundStyle.grouped.restyled { style in
        style.color = .modalSelection
    }
}

extension SectionStyle.Background {
    static let plain = SectionStyle.Background(style: .plain)
    static let plainSelected = SectionStyle.Background(style: .plainSelected)

    static let list = SectionStyle.Background(style: .list)
    static let listSelected = SectionStyle.Background(style: .listSelected)

    static let grouped = SectionStyle.Background(style: .grouped)
    static let groupedSelected = SectionStyle.Background(style: .groupedSelected)
}

extension CGFloat {
    static var standardRowHeight: CGFloat { return isRegular ? 60 : 56 }
    static var standardItemSpacing: CGFloat { return isRegular ? 12 : 10 }
    static let standardHeaderHeight: CGFloat = 34
    static let standardFooterHeight: CGFloat = 22
}

extension UIImage {
    static let plainSectionHeader = SegmentBackgroundStyle(color: .modalFormBackground, border: .bottomSeparator)?.image()
    static let plainFormSectionHeader = SegmentBackgroundStyle(color: .modalFormBackground, border: .none)?.image()
    static let plainSectionFooter = SegmentBackgroundStyle(color: .clear, border: .none)?.image()
}

final class FormScrollView: UIScrollView { }
final class FormTableView: UITableView { }
final class ListTableView: UITableView { }
