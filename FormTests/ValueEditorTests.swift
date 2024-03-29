//
//  Copyright © 2020 PayPal Inc. All rights reserved.
//

import XCTest
import Form

class ValueEditorTests: XCTestCase {
    /// '<' is delete backward, 'r' resets the editor, 'R' toggles `shouldResetOnInsertion`
    @discardableResult
    func test<TE: TextEditor>(_ editor: TE, _ inputSequence: String, _ expectedValue: TE.Value, _ distance: Int) -> TE where TE.Value: Equatable {
        var editor = editor
        for character in inputSequence {
            if character == "<" {
                editor.deleteBackward()
            } else if character == "r" {
                editor.reset()
            } else if character == "R" {
                editor.shouldResetOnInsertion = !editor.shouldResetOnInsertion
            } else {
                editor.insertCharacter(character)
            }
        }

        XCTAssertEqual(editor.value, expectedValue, "Comparing values")
        XCTAssertEqual(editor.text.distance(from: editor.insertionIndex, to: editor.text.endIndex), distance, "Comparing insertion index")

        return editor
    }

    func testReset() {
        let editor = ValueEditor<String>()

        test(editor, "r", "", 0)
        test(editor, "1234rrrr", "", 0)
        test(editor, "111111111111111111111111111111111r", "", 0)
        test(editor, "1234<<r", "", 0)
        test(editor, "123<<<34r", "", 0)
        test(editor, "12345r<", "", 0)
        test(editor, "12345r111", "111", 0)
        test(editor, "12345r111<", "11", 0)
    }

    func testResetOnInsertion_isDisabledByDefault() {
        let editor = ValueEditor<String>()
        XCTAssertFalse(editor.shouldResetOnInsertion)
    }

    func testResetOnInsertion_isDisabledAfterInsertion() {
        var editor = ValueEditor<String>()

        editor.shouldResetOnInsertion = true
        editor.insertCharacter("1")
        XCTAssertFalse(editor.shouldResetOnInsertion)
    }

    func testResetOnInsertion_ignoresInvalidInput() {
        let value = "123"
        let invalidCharacter: Character = "a"
        var editor = ValueEditor<String>(value: value, isValidCharacter: { $0 != invalidCharacter })

        editor.shouldResetOnInsertion = true
        editor.insertCharacter(invalidCharacter)

        XCTAssert(editor.shouldResetOnInsertion)
        XCTAssertEqual(editor.value, value)
    }

    func testResetOnInsertion() {
        let editor = ValueEditor<String>()

        test(editor, "12R", "12", 0)
        test(editor, "12R3", "3", 0)
        test(editor, "1R23", "23", 0)
        test(editor, "12RR3", "123", 0)
        test(editor, "12RRR3", "3", 0)
        test(editor, "12R23R34R45", "45", 0)
        test(editor, "12R<", "1", 0)
        test(editor, "12R<3", "13", 0)
        test(editor, "12RR<3", "13", 0)
        test(editor, "12R34r", "", 0)
    }

    func testResetOnInsertion_whenValueHasMaximumCharacters_resetsOnInput() {
        let editor = ValueEditor<String>(maxCharacters: 5)

        test(editor, "1234567890", "12345", 0)
        test(editor, "123456R3", "3", 0)
    }

    func testComputesCorrectAccessibilityValue() {
        let defaultEditor = ValueEditor<String>(value: "test")
        let customEditor = ValueEditor(
            value: "test",
            defaultValue: "",
            valueToText: { $0 },
            valueToAccessibilityValue: { $0 + " modified" },
            textToValue: { $0 },
            isValidCharacter: { _ in true },
            minCharacters: 0,
            maxCharacters: .max,
            textAndInsertionIndex: { ($0, $0.endIndex) }
        )

        XCTAssertEqual(defaultEditor.accessibilityValue, defaultEditor.text)
        XCTAssertEqual(customEditor.accessibilityValue, "test modified")
    }
}
