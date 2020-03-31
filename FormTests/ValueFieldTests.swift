//
//  Copyright © 2020 iZettle. All rights reserved.
//

import XCTest
import UIKit
import Flow
@testable import Form

class ValueFieldTests: XCTestCase {

    override class func tearDown() {
        super.tearDown()
        setPasteboardText("")
    }

    func testResetBeforeNextInsert_byDefault_isDisabled() {
        let field = ValueField(value: 42)
        field.insertText("1")

        XCTAssertFalse(field.shouldResetBeforeNextInsertion)
    }

    func testResetBeforeNextInsert_whenEnabled_currentValueIsReset() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = true
        field.insertText("111")

        XCTAssertEqual(field.value, 111)
    }

    func testResetBeforeNextInsert_whenDisabled_currentValueIsNotReset() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = false
        field.insertText("1")

        XCTAssertEqual(field.value, 421)
    }

    func testResetBeforeNextInsert_whenInsertingInvalidText_currentValueIsNotReset() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = true
        field.insertText("\n")

        XCTAssertEqual(field.value, 42)
    }

    func testResetBeforeNextInsert_onInsert_isDisabled() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = true
        field.insertText("1")

        XCTAssertFalse(field.shouldResetBeforeNextInsertion)
    }

    func testResetBeforeNextInsert_pastingTextWhenEnabled_currentValueIsReset() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = true

        setPasteboardText("111")
        field.paste(nil)

        XCTAssertEqual(field.value, 111)
    }

    func testResetBeforeNextInsert_afterPastingText_isDisabled() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = true

        setPasteboardText("111")
        field.paste(nil)

        XCTAssertFalse(field.shouldResetBeforeNextInsertion)
    }

    func testResetBeforeNextInsert_pastingTextWhenDisabled_currentValueIsNotReset() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = false

        setPasteboardText("111")
        field.paste(nil)

        XCTAssertEqual(field.value, 42111)
    }

    func testResetBeforeNextInsert_whenPastingInvalidText_currentValueIsNotReset() {
        let field = ValueField(value: 42)
        field.shouldResetBeforeNextInsertion = true

        setPasteboardText("\n")
        field.paste(nil)

        XCTAssertEqual(field.value, 42)
    }
}

private func setPasteboardText(_ text: String) {
    UIPasteboard.general.string = text
}
