//
//  TextStyleTests.swift
//  FormTests
//
//  Created by Mayur Deshmukh on 11/02/19.
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Form

class TextStyleTests: XCTestCase {

    let textSytle = TextStyle(font: .systemFont(ofSize: 14.0), color: .red, minimumScalingFactor: 0.5)

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

    func testTextStyleMinimumScalingFactor() {
        let textStyle1 = TextStyle(font: .systemFont(ofSize: 14.0), color: .red)
        XCTAssertEqual(textStyle1.minimumScalingFactor, 1.0)

        let textStyle2 = TextStyle(font: .systemFont(ofSize: 14.0), color: .red, minimumScalingFactor: 0.5)
        XCTAssertEqual(textStyle2.minimumScalingFactor, 0.5)
    }

    func testUILabelStyling() {
        let label = UILabel(value: "Lorem ipsum", style: textSytle)
        XCTAssertEqual(label.minimumScaleFactor, textSytle.minimumScalingFactor)
    }
}
