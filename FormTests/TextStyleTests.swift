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
}
