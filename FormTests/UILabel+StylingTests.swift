//
//  UILabel+StylingTests.swift
//  FormTests
//
//  Created by Nataliya Patsovska on 2019-03-19.
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Form

class UILabelStylingTests: XCTestCase {

    func testRetrievingLabelStyleAndTextAfterCreation_plainStyle() {
        let textStyle = TextStyle.plain
        let randomLabelText = randomText()

        let label = UILabel(value: randomLabelText, style: textStyle)

        XCTAssertEqual(label.style, textStyle)
        XCTAssertEqual(label.text, randomLabelText)
        XCTAssertEqual(label.text, label.value.displayValue)
    }

    func testRetrievingLabelStyleAndTextAfterCreation_styleWithCustomAttributes() {
        let textStyle = TextStyle.withCustomAttributes
        let randomLabelText = randomText()

        let label = UILabel(value: randomLabelText, style: textStyle)

        XCTAssertEqual(label.style, textStyle)
        XCTAssertEqual(label.text, randomLabelText)
        XCTAssertEqual(label.text, label.value.displayValue)
    }

    func testSettingSameLabelValueAfterResettingText_plainStyle() {
        let textStyle = TextStyle.plain
        let randomLabelText = randomText()

        let label = UILabel(value: randomLabelText, style: textStyle)
        label.text = nil
        label.value = randomLabelText

        XCTAssertEqual(label.text, randomLabelText)
    }

    func testSettingSameLabelValueAfterResettingText_styleWithCustomAttributes() {
        let textStyle = TextStyle.withCustomAttributes
        let randomLabelText = randomText()

        let label = UILabel(value: randomLabelText, style: textStyle)
        label.text = nil
        label.value = randomLabelText

        XCTAssertEqual(label.text, randomLabelText)
    }

    func testUpdatingLabelStyle() {
        let textStyle = TextStyle.plain
        let randomLabelText = randomText()

        let label = UILabel(value: randomLabelText, style: textStyle)
        let textStyle2 = TextStyle.withCustomAttributes
        label.style = textStyle2

        XCTAssertNotEqual(label.style, textStyle)
        XCTAssertEqual(label.style, textStyle2)
    }

    func testAssigningStyleToLabelCreatedWithoutStyle() {
        let label = UILabel(frame: .zero)
        let textStyle = TextStyle.plain

        label.style = textStyle

        XCTAssertEqual(label.style, textStyle)
        XCTAssertEqual(label.text, "")
    }

    func testAssigningStyleToLabelCreatedWithoutStylePreservesText() {
        let label = UILabel(frame: .zero)
        let randomLabelText = randomText()

        label.text = randomLabelText
        let textStyle = TextStyle.plain
        label.style = textStyle

        XCTAssertEqual(label.style, textStyle)
        XCTAssertEqual(label.text, randomLabelText)
    }

    // MARK: - Helpers
    private func randomText() -> String {
        return UUID().uuidString
    }
}

private extension TextStyle {
    static let plain = TextStyle(font: .systemFont(ofSize: 14.0), color: .black)
    static let withCustomAttributes = TextStyle.plain.restyled { $0.letterSpacing = 1.0 }
}
