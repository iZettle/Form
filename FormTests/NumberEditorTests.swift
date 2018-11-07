//
//  NumberEditorTests.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-08-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import XCTest
import Form

class DecimalEditorTests: XCTestCase {
    /// '<' is delete backward
    @discardableResult
    func test<TE: TextEditor>(_ editor: TE, _ characters: String, _ expectedText: String, _ expectedValue: TE.Value, _ distance: Int) -> TE where TE.Value: Equatable {
        var editor = editor
        for character in characters {
            if character == "<" {
                editor.deleteBackward()
            } else {
                editor.insertCharacter(character)
            }
        }
        XCTAssertEqual(editor.value, expectedValue, "Comparing values")
        XCTAssertEqual(editor.text, expectedText, "Comparing text")
        XCTAssertEqual(editor.text.distance(from: editor.insertionIndex, to: editor.text.endIndex), distance, "Comparing insertion index")

        return editor
    }

    var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 3
        return formatter
    }

    func testMinFractionZero() {
        let formatter = decimalFormatter
        let editor = NumberEditor(formatter: formatter)

        test(editor, "1", "1", 1, 0)
        test(editor, "1.", "1.", 1, 0)
        test(editor, "1234", "1,234", 1234, 0)
        test(editor, "1.2", "1.2", 1.2, 0)

        test(editor, ".0", "0.0", 0, 0)
        test(editor, "000.0", "0.0", 0, 0)
        test(editor, "00000000", "0", 0, 0)
        test(editor, "00000.000", "0.000", 0, 0)
        test(editor, "00000.0000", "0.000", 0, 0)
        test(editor, "00000.0001", "0.000", 0, 0)

        test(editor, "12.3<", "12.", 12, 0)
        test(editor, "12.3<<", "12", 12, 0)
        test(editor, "12.3<<<", "1", 1, 0)
        test(editor, "00000<<<<<", "0", 0, 0)
        test(editor, "11111<<<<<", "0", 0, 0)
        test(editor, "1234<<", "12", 12, 0)
        test(editor, "12<<34", "34", 34, 0)
    }

    func testMinFractionTwo() {
        let formatter = decimalFormatter
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        let editor = NumberEditor(formatter: formatter)

        test(editor, "1", "0.01", 0.01, 0)

        test(editor, "0", "0.00", 0, 0)
        test(editor, "1", "0.01", 0.01, 0)
        test(editor, "1.", "0.01", 0.01, 0)
        test(editor, "1234", "12.34", 12.34, 0)
        test(editor, "1.2", "0.12", 0.12, 0)

        test(editor, ".0", "0.00", 0, 0)
        test(editor, "000.0", "0.00", 0, 0)
        test(editor, "00000000", "0.00", 0, 0)
        test(editor, "00000.000", "0.00", 0, 0)
        test(editor, "00000.0000", "0.00", 0, 0)
        test(editor, "00000.0001", "0.01", 0.01, 0)

        test(editor, "00000<<<<<", "0.00", 0, 0)
        test(editor, "11111<<<<<", "0.00", 0, 0)
        test(editor, "1234<<", "0.12", 0.12, 0)
        test(editor, "12<<34", "0.34", 0.34, 0)
    }

    func testMaxIntegerDigits() {
        let formatter = decimalFormatter
        formatter.maximumFractionDigits = 3
        formatter.maximumIntegerDigits = 5

        let editor = NumberEditor(formatter: formatter)

        test(editor, "11111", "11,111", 11111, 0)
        test(editor, "111111", "11,111", 11111, 0)
        test(editor, "111111.5", "11,111.5", 11111.5, 0)
        test(editor, "111111.25", "11,111.25", 11111.25, 0)
        test(editor, "111111.125", "11,111.125", 11111.125, 0)
        test(editor, "111111<2", "11,112", 11112, 0)
        test(editor, "111111<<22", "11,122", 11122, 0)

        test(editor, "11111.", "11,111.", 11111, 0)
        test(editor, "111111.5", "11,111.5", 11111.5, 0)
        test(editor, "111111.5<<2", "11,111", 11111, 0)
        test(editor, "111111.5<<<2", "11,112", 11112, 0)
    }

    func testMaxIntegerDigitsMinFractionTwo() {
        let formatter = decimalFormatter
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.maximumIntegerDigits = 5

        let editor = NumberEditor(formatter: formatter)

        test(editor, "1111111", "11,111.11", 11111.11, 0)
        test(editor, "11111111", "11,111.11", 11111.11, 0)
        test(editor, "11111111<<22", "11,111.22", 11111.22, 0)
    }

    func testNumberFormatterWithAffixes() {
        let formatter = decimalFormatter
        formatter.positivePrefix = "PRE01 "
        formatter.positiveSuffix = " POST20"

        let editor = NumberEditor(formatter: formatter)

        test(editor, "1", "PRE01 1 POST20", 1, 7)
        test(editor, "123.123", "PRE01 123.123 POST20", 123.123, 7)
    }

    func testDeletions() {
        var decimalEditor = NumberEditor(formatter: NumberFormatter())
        for _ in 0..<10 {
            decimalEditor.deleteBackward()
        }
        XCTAssertEqual(decimalEditor.value, NSDecimalNumber.zero)
    }

    func testNegative() {
        let formatter = decimalFormatter
        let editor = NumberEditor(formatter: formatter)

        test(editor, "-", "-0", 0, 0)
        test(editor, "-1", "-1", -1, 0)
        test(editor, "-1<", "-0", 0, 0)
        test(editor, "-1<<", "0", 0, 0)
        test(editor, "-123", "-123", -123, 0)
        test(editor, "-12-3", "123", 123, 0)
        test(editor, "-12-3-", "-123", -123, 0)
    }

    func testNegativeWithFraction() {
        let formatter = decimalFormatter
        formatter.maximumFractionDigits = 3
        let editor = NumberEditor(formatter: formatter)

        test(editor, "-.", "-0.", 0, 0)
        test(editor, ".-", "-0.", 0, 0)
        test(editor, "-.<", "-0", 0, 0)
        test(editor, "-.<<", "0", 0, 0)
        test(editor, "-.1", "-0.1", -0.1, 0)
        test(editor, "-.12-", "0.12", 0.12, 0)
    }

    func testNegativeMinFractionTwoAndPrefix() {
        let formatter = decimalFormatter
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "P"
        formatter.negativePrefix = "-N"

        let editor = NumberEditor(formatter: formatter)

        test(editor, "-", "-N0.00", 0, 0)
        test(editor, "-1", "-N0.01", -0.01, 0)
        test(editor, "-1<", "-N0.00", 0, 0)
        test(editor, "-1<<", "P0.00", 0, 0)
        test(editor, "-123", "-N1.23", -1.23, 0)
        test(editor, "-12-3", "P1.23", 1.23, 0)
        test(editor, "-12-3-", "-N1.23", -1.23, 0)
    }
}
