//
//  ValueEditor.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-18.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit

/// A concrete implementation of a text editor using provided functions to implement `TextEditor`.
public struct ValueEditor<Value>: TextEditor {
    private let _isValidCharacter: ((Character) -> Bool)
    private let initialValue: Value
    private let valueToText: (Value) -> String
    private let _textAndInsertionIndex: (Value) -> (String, String.Index)
    private let textToValue: (String) -> Value?
    private let minCharacters: Int
    private let maxCharacters: Int

    public var value: Value

    /// Creates a new instance with the ìnitial value of `value`.
    /// Parameters:
    ///   - valueToText: How to convert a `Value` to the editable text representation part of the value.
    ///   - textToValue: How to convert the editable text representation part of value back to a `Value`.
    ///   - isValidCharacter: Whether a character is a valid input to build a value.
    ///   - minCharacters: Min characters of the editable text representation of value, defaults to zero
    ///   - maxCharacters: Max characters of the editable text representation of value, defaults to `.max`
    ///   - textAndInsertionIndex: Format a value for display (adding potential prefix, postfix or other formatting)
    ///       and the index for insertions, useful for placing cursors etc.
    public init(value: Value, valueToText: @escaping (Value) -> String, textToValue: @escaping (String) -> Value?, isValidCharacter: @escaping ((Character) -> Bool), minCharacters: Int = 0, maxCharacters: Int = .max, textAndInsertionIndex: @escaping (Value) -> (String, String.Index)) {
        self.value = value
        self.initialValue = value
        self.valueToText = valueToText
        self.textToValue = textToValue
        _textAndInsertionIndex = textAndInsertionIndex
        self._isValidCharacter = isValidCharacter
        self.minCharacters = minCharacters
        self.maxCharacters = maxCharacters
    }

    public var textAndInsertionIndex: (text: String, index: String.Index) {
        return _textAndInsertionIndex(value)
    }

    public func isValidCharacter(_ char: Character) -> Bool {
        return _isValidCharacter(char)
    }

    mutating public func insertCharacter(_ char: Character) {
        guard _isValidCharacter(char) && valueToText(value).count < maxCharacters else { return }
        if let value = textToValue(valueToText(value) + String(char)) {
            self.value = value
        }
    }

    mutating public func deleteBackward() {
        var text = valueToText(value)
        guard text.count > minCharacters else { return }
        text.remove(at: text.index(before: text.endIndex))
        if let value = textToValue(text) {
            self.value = value
        }
    }

    mutating public func reset() {
        self.value = initialValue
    }
}

public extension ValueEditor where Value == String {
    init(value: Value = "", isValidCharacter: @escaping (Character) -> Bool = { _ in true }, minCharacters: Int = 0, maxCharacters: Int = .max, textAndInsertionIndex: @escaping (Value) -> (String, String.Index) = { ($0, $0.endIndex) }) {
        self.init(value: value, valueToText: { $0 }, textToValue: { $0 }, isValidCharacter: isValidCharacter, minCharacters: minCharacters, maxCharacters: maxCharacters, textAndInsertionIndex: textAndInsertionIndex)
    }
}

public extension ValueEditor where Value == String {
    init(value: Value = "", isValidCharacter: @escaping (Character) -> Bool = { _ in true }, minCharacters: Int = 0, maxCharacters: Int = .max, prefix: String = "", suffix: String = "") {
        self.init(value: value, isValidCharacter: isValidCharacter, minCharacters: minCharacters, maxCharacters: maxCharacters) {
            let text = prefix + $0 + suffix
            return (text, text.index(text.startIndex, offsetBy: prefix.count + $0.count))
        }
    }
}
