//
//  TextStyleTests.swift
//  FormTests
//
//  Created by Mayur Deshmukh on 12/02/19.
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Form

class TextStyleTests: XCTestCase {

    func testTextStyleEquality() {
        let textStyle1 = TextStyle(font: .systemFont(ofSize: 14.0), color: .red, alignment: .left, lineBreakMode: .byWordWrapping)
        let textStyle2 = TextStyle(font: .systemFont(ofSize: 14.0), color: .red, alignment: .left, lineBreakMode: .byWordWrapping)
        let textStyle3 = TextStyle(font: .systemFont(ofSize: 14.0), color: .red, alignment: .left, lineBreakMode: .byCharWrapping)
        let textStyle4 = TextStyle(font: .systemFont(ofSize: 15.0), color: .red, alignment: .left, lineBreakMode: .byWordWrapping)
        let textStyle5 = TextStyle(font: .systemFont(ofSize: 14.0), color: .green, alignment: .left, lineBreakMode: .byWordWrapping)

        XCTAssertEqual(textStyle1, textStyle2)
        XCTAssertNotEqual(textStyle1, textStyle3)
        XCTAssertNotEqual(textStyle1, textStyle4)
        XCTAssertNotEqual(textStyle1, textStyle5)
    }

    func testCustomLineHeightIsSet_biggerThanFontLineHeight() {
        let font = UIFont.systemFont(ofSize: 14.0)
        let textStyle = TextStyle(font: font, color: .red).restyled { $0.lineHeight = 30.0 }
        XCTAssertEqual(textStyle.lineHeight, 30.0)
    }

    func testCustomLineHeightIsSet_smallerThanFontLineHeight_biggerThanFontSize() {
        let font = UIFont.systemFont(ofSize: 14.0)
        let textStyle = TextStyle(font: font, color: .red).restyled { $0.lineHeight = 15.0 }
        XCTAssertEqual(textStyle.lineHeight, 15.0)
    }

    func testCustomLineHeightIsCorrectedToFontSize_smallerThanFontSize() {
        let font = UIFont.systemFont(ofSize: 14.0)
        let textStyle = TextStyle(font: font, color: .red).restyled { $0.lineHeight = 13.0 }
        XCTAssertEqual(textStyle.lineHeight, 14.0)
    }

    func testIncreasingLineSpacingIncreasesLineHeight() {
        let font = UIFont.systemFont(ofSize: 14.0)
        var textStyle = TextStyle(font: font, color: .red)
        let initialLineHeight = textStyle.lineHeight
        textStyle.lineSpacing += 2.0
        XCTAssertGreaterThan(textStyle.lineHeight, initialLineHeight)
    }

    func testIncreasingLineHeightIncreasesLineSpacing() {
        let font = UIFont.systemFont(ofSize: 14.0)
        var textStyle = TextStyle(font: font, color: .red)
        let initialLineSpacing = textStyle.lineSpacing
        textStyle.lineHeight += 2.0
        XCTAssertGreaterThan(textStyle.lineSpacing, initialLineSpacing)
    }
}
