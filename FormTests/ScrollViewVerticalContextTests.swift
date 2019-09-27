//
//  UIScrollView+KeyboardTests.swift
//  FormTests
//
//  Created by Nataliya Patsovska on 2019-09-07.
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
@testable import Form
import Flow

class ScrollViewVerticalContextTests: XCTestCase {
    func testFocusPosition_noOffsetContext() {
        let verticalContext = ScrollViewVerticalContext(
            visibleRectHeight: 100,
            visibleRectOffsetY: 0,
            visibleRectInsetTop: 0,
            visibleRectInsetBottom: 0
        )

        // whitin the visible area
        XCTAssertNil(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 0, width: 100, height: 50)))
        XCTAssertNil(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 50, width: 100, height: 50)))

        // below the visible area
        XCTAssertEqual(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 51, width: 100, height: 50)), 101)
    }

    func testFocusPosition_yOffsetContext() {
        let verticalContext = ScrollViewVerticalContext(
            visibleRectHeight: 100,
            visibleRectOffsetY: 50,
            visibleRectInsetTop: 0,
            visibleRectInsetBottom: 0
        )

        // whitin the visible area
        XCTAssertNil(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 50, width: 100, height: 50)))
        XCTAssertNil(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 100, width: 100, height: 50)))

        // above the visible area
        XCTAssertEqual(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 49, width: 100, height: 50)), 49)

        // below the visible area
        XCTAssertEqual(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 101, width: 100, height: 50)), 151)
    }

    func testFocusPosition_insettedContext() {
        let verticalContext = ScrollViewVerticalContext(
            visibleRectHeight: 100,
            visibleRectOffsetY: 50,
            visibleRectInsetTop: -10,
            visibleRectInsetBottom: 20
        )

        // whitin the visible area
        XCTAssertNil(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 60, width: 100, height: 50)))
        XCTAssertNil(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 90, width: 100, height: 50)))

        // above the visible area
        XCTAssertEqual(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 59, width: 100, height: 50)), 59)

        // below the visible area
        XCTAssertEqual(verticalContext.targetFocusPosition(for: CGRect(x: 0, y: 91, width: 100, height: 50)), 141)
    }
}
