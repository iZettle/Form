//
//  Copyright © 2020 PayPal Inc. All rights reserved.
//

import XCTest
import Flow

@testable import Form

class ValueFieldTests: XCTestCase {

    lazy var window: UIWindow = {
        let window = UIWindow()
        window.frame.size = .init(width: 100, height: 100)
        window.makeKeyAndVisible()

        return window
    }()

    func createField() -> (ValueField<String>, Disposable) {
        let field = ValueField(value: "", editor: ValueEditor())

        // add the field to a window so that it can become first responder
        window.embedView(field)

        return (field, Disposer { field.removeFromSuperview() })
    }

    func createFieldAndMakeItFirstResponder(
        beforeMakingFieldFirstResponder: @escaping (ValueField<String>) -> Void,
        afterMakingFieldFirstResponder: @escaping (ValueField<String>) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) -> XCTestExpectation {
        let (field, bag) = createField()

        beforeMakingFieldFirstResponder(field)

        _ = field.becomeFirstResponder()
        let becameFirstResponder = expectation(description: "Responder status changed")

        // the change of first responder may not happen immediately
        DispatchQueue.main.async {
            XCTAssert(field.isFirstResponder, file: file, line: line)
            afterMakingFieldFirstResponder(field)

            bag.dispose()
            becameFirstResponder.fulfill()
        }

        return becameFirstResponder
    }

    func testTextHighlight_whenNotAFirstResponder_isDisabled() {
        let (field, _) = createField()

        XCTAssertFalse(field.isFirstResponder)
        XCTAssertFalse(field.shouldHighlightText)

        field.shouldResetOnInsertion = true
        XCTAssertFalse(field.shouldHighlightText)
    }

    func testTextHighlight_whenResetOnInsertionIsDisabled_isDisabled() {
        let fieldBecameFirstResponder = createFieldAndMakeItFirstResponder(
            beforeMakingFieldFirstResponder: { field in
                field.shouldResetOnInsertion = false
                XCTAssertFalse(field.shouldHighlightText)
            },
            afterMakingFieldFirstResponder: { field in
                XCTAssertFalse(field.shouldHighlightText)
            }
        )

        wait(for: [fieldBecameFirstResponder], timeout: 1)
    }

    func testTextHighlight_whenIsAFirstResponderAndResetOnInsertionIsEnabled_isEnabled() {
        let fieldBecameFirstResponder = createFieldAndMakeItFirstResponder(
            beforeMakingFieldFirstResponder: { field in
                field.shouldResetOnInsertion = true
            },
            afterMakingFieldFirstResponder: { field in
                XCTAssert(field.shouldHighlightText)
            }
        )

        wait(for: [fieldBecameFirstResponder], timeout: 1)
    }

    func testTextHighlight_afterTextIsInserted_isDisabled() {
        let fieldBecameFirstResponder = createFieldAndMakeItFirstResponder(
            beforeMakingFieldFirstResponder: { field in
                field.shouldResetOnInsertion = true
            },
            afterMakingFieldFirstResponder: { field in
                field.insertText("foo")
                XCTAssertFalse(field.shouldHighlightText)
            }
        )

        wait(for: [fieldBecameFirstResponder], timeout: 1)
    }

    func testTextHighlight_afterFieldBecomesAndResignsFirstResponder_isDisabled() {
        let fieldResignedFirstResponder = expectation(description: "Field resigned first responder")

        let fieldBecameFirstResponder = createFieldAndMakeItFirstResponder(
            beforeMakingFieldFirstResponder: { field in
                field.shouldResetOnInsertion = true
            },
            afterMakingFieldFirstResponder: { field in
                XCTAssert(field.shouldHighlightText)
                _ = field.resignFirstResponder()

                DispatchQueue.main.async {
                    XCTAssertFalse(field.isFirstResponder)
                    XCTAssertFalse(field.shouldHighlightText)
                    fieldResignedFirstResponder.fulfill()
                }
            }
        )

        wait(for: [fieldBecameFirstResponder, fieldResignedFirstResponder], timeout: 1)
    }

    func testTextHighlight_afterTextIsPasted_isDisabled() {
        let fieldBecameFirstResponder = createFieldAndMakeItFirstResponder(
            beforeMakingFieldFirstResponder: { field in
                UIPasteboard.general.string = "foo"
                field.shouldResetOnInsertion = true
            },
            afterMakingFieldFirstResponder: { field in
                field.paste(nil)
                XCTAssertFalse(field.shouldHighlightText)
            }
        )

        wait(for: [fieldBecameFirstResponder], timeout: 1)
    }

    func testTextHighlight_afterTextIsDeleted_isDisabled() {
        let fieldBecameFirstResponder = createFieldAndMakeItFirstResponder(
            beforeMakingFieldFirstResponder: { field in
                field.insertText("foo")
                field.shouldResetOnInsertion = true
            },
            afterMakingFieldFirstResponder: { field in
                field.deleteBackward()
                XCTAssertFalse(field.shouldHighlightText)
            }
        )

        wait(for: [fieldBecameFirstResponder], timeout: 1)
    }
}
