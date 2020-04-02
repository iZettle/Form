//
//  Copyright © 2020 iZettle. All rights reserved.
//

import XCTest
import Form

class ValueEditorTests: XCTestCase {
    /// '<' is delete backward, 'R' toggles `shouldResetOnInsertion`
    @discardableResult
    func test(_ editor: ValueEditor<String>, _ inputSequence: String, _ expectedValue: String, _ distance: Int, file: StaticString = #file, line: UInt = #line) -> ValueEditor<String> {
        var editor = editor
        for character in inputSequence {
            if character == "<" {
                editor.deleteBackward()
            } else if character == "R" {
                editor.shouldResetOnInsertion = !editor.shouldResetOnInsertion
            } else {
                editor.insertCharacter(character)
            }
        }

        XCTAssertEqual(editor.value, expectedValue, "Comparing values", file: file, line: line)
        XCTAssertEqual(editor.text.distance(from: editor.insertionIndex, to: editor.text.endIndex), distance, "Comparing insertion index", file: file, line: line)

        return editor
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
        test(editor, "12R<3", "3", 0)
        test(editor, "12RR<3", "13", 0)
        test(editor, "12R34R1<", "", 0)
    }
}
