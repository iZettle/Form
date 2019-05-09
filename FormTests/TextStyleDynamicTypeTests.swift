//
//  TextStyleDynamicTypeTests.swift
//  FormTests
//
//  Created by Nataliya Patsovska on 2019-05-09.
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Flow
@testable import Form

class TextStyleDynamicTypeTests: XCTestCase {
    let contentSizeCategory = ReadWriteSignal(UIContentSizeCategory.small)

    func testThatScaledFontIncreasesWithSizeCategory() {
        let textStyle = TextStyle.createDynamicStyle(contentSizeCategory: contentSizeCategory.readOnly())

        contentSizeCategory.value = .small
        let textFontScaledToSmall = textStyle.scaledFont

        contentSizeCategory.value = .large
        let textFontScaledtoLarge = textStyle.scaledFont

        contentSizeCategory.value = .extraLarge
        let textFontScaledToExtraLarge = textStyle.scaledFont

        XCTAssertLessThan(textFontScaledToSmall.pointSize, textFontScaledtoLarge.pointSize)
        XCTAssertLessThan(textFontScaledtoLarge.pointSize, textFontScaledToExtraLarge.pointSize)
    }

    func testThatScalingResyledTextStyleKeepsTheRestyling() {
        let textStyle = TextStyle.createDynamicStyle(contentSizeCategory: contentSizeCategory.readOnly())

        let restyledTextStyle = textStyle.restyled { $0.font = UIFont.systemFont(ofSize: $0.font.pointSize, weight: .heavy) }

        XCTAssertEqual(textStyle.scaledFont, textStyle.scaledFont)
        XCTAssertNotEqual(restyledTextStyle.scaledFont, textStyle.scaledFont)
    }

    // MARK: - UILabel + Dynamic Type
    func testThatLabelFontSizeIncreasesWhenSizeCategoryIncreases() {
        // given
        contentSizeCategory.value = .small

        let textStyle = TextStyle.createDynamicStyle(contentSizeCategory: contentSizeCategory.readOnly())
        let label = UILabel(value: "Test", style: textStyle)
        let initialLabelFont = label.font

        // when
        contentSizeCategory.value = .extraLarge

        // then
        XCTAssertLessThan(initialLabelFont!.pointSize, label.font!.pointSize)
    }

    func testThatLabelFontUpdatesWhenSettingNewLabelStyle() {
        // given
        let textStyle = TextStyle.createDynamicStyle(ofSize: 14, contentSizeCategory: ReadSignal(.small))
        let label = UILabel(value: "Test", style: textStyle)
        let labelFontInitial = label.font

        // when
        label.style = TextStyle.createDynamicStyle(ofSize: 18, contentSizeCategory: ReadSignal(.small))
        let labelFontAfterStyleUpdate = label.font

        // then
        XCTAssertLessThan(labelFontInitial!.pointSize, labelFontAfterStyleUpdate!.pointSize)
    }

    func testThatLabelListensForUpdatesOnlyForLatestStyle() {
        // given
        let contentSizeCategory1 = ReadWriteSignal(UIContentSizeCategory.small)
        let contentSizeCategory2 = ReadWriteSignal(UIContentSizeCategory.small)
        let textStyle1 = TextStyle.createDynamicStyle(ofSize: 14, contentSizeCategory: contentSizeCategory1.readOnly())
        let textStyle2 = TextStyle.createDynamicStyle(ofSize: 14, contentSizeCategory: contentSizeCategory2.readOnly())

        let label = UILabel(value: "Test", style: textStyle1)
        label.style = textStyle2
        let labelFontAfterStyleUpdate = label.font

        // when
        contentSizeCategory1.value = .extraLarge

        // then
        XCTAssertEqual(labelFontAfterStyleUpdate!.pointSize, label.font!.pointSize)

        // when
        contentSizeCategory2.value = .extraLarge

        // then
        XCTAssertLessThan(labelFontAfterStyleUpdate!.pointSize, label.font!.pointSize)
    }

    func testThatLabelWithTextStyleDoesNotLeak() { // since it has stored subscriptions where self needs to be referenced weakly
        // given
        let textStyle = TextStyle.createDynamicStyle(contentSizeCategory: contentSizeCategory.readOnly())
        var label: UILabel? = .init(value: "Test", style: textStyle)

        // when
        weak var weakLabel = label
        label = nil

        // then
        XCTAssertNil(weakLabel)
    }
}

extension TextStyle {
    static func createDynamicStyle(ofSize size: CGFloat = 14.0, contentSizeCategory: ReadSignal<UIContentSizeCategory>) -> TextStyle {
        let font = UIFont.systemFont(ofSize: size)
        let textStyle = TextStyle(font: font, color: .red, dynamicTypeMapping: .body, contentSizeCategory: contentSizeCategory)
        return textStyle
    }
}
