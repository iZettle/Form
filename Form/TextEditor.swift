//
//  TextEditor.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-18.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

/// Conforming types defines how to edit the text representation of values of type `Value`.
public protocol TextEditor {
    associatedtype Value

    /// The current value of the edited text
    var value: Value { get set }

    /// The value to which the editor will be reset.
    var defaultValue: Value { get }

    /// This property emulates the behavior of `UITextField.clearOnInsertion`. The default value is `false`. When the
    /// value is `true`, inserting new characters resets `value` to `defaultValue` and sets this property back to
    /// `false`.
    var shouldResetOnInsertion: Bool { get set }

    /// The current formatted text of value and the index into text where insertions happen, useful for placing cursors etc.
    var textAndInsertionIndex: (text: String, index: String.Index) { get }

    mutating func insertCharacter(_ char: Character)

    mutating func deleteBackward()

    /// Reset the value of editor to `defaultValue`
    mutating func reset()
}

public extension TextEditor {
    var text: String {
        return textAndInsertionIndex.text
    }

    var insertionIndex: String.Index {
        return textAndInsertionIndex.index
    }

    mutating func insertText(_ text: String) {
        for char in text {
            insertCharacter(char)
        }
    }

    mutating func deleteBackward(repeatCount: Int) {
        for _ in 0..<repeatCount {
            deleteBackward()
        }
    }

    mutating func reset() {
        self.value = self.defaultValue
    }
}

public extension TextEditor {
    var anyEditor: AnyTextEditor<Value> {
        return _AnyTextEditor(self)
    }
}

public extension Character {
    var isDigit: Bool {
        return "0123456789".contains(String(self))
    }
}

public func isDigit(_ character: Character) -> Bool {
    return character.isDigit
}

public class AnyTextEditor<Value>: TextEditor {

    public var value: Value {
        get { fatalError() }
        // swiftlint:disable:next unused_setter_value
        set { fatalError() }
    }

    public var defaultValue: Value {
        fatalError()
    }

    public var shouldResetOnInsertion: Bool {
        get { fatalError() }
        // swiftlint:disable:next unused_setter_value
        set { fatalError() }
    }

    public var textAndInsertionIndex: (text: String, index: String.Index) {
        fatalError()
    }

    public func insertCharacter(_ char: Character) {
        fatalError()
    }

    public func deleteBackward() {
        fatalError()
    }

    public func reset() {
        fatalError()
    }
}

final class KeyPathTextEditor<Value, Editor: TextEditor>: TextEditor {
    private var editor: Editor
    private let keyPath: WritableKeyPath<Value, Editor.Value>

    init(value: Value, keyPath: WritableKeyPath<Value, Editor.Value>, editor: Editor) {
        self.value = value
        self.editor = editor
        self.keyPath = keyPath
    }

    var value: Value {
        didSet { editor.value = value[keyPath: keyPath] }
    }

    public var defaultValue: Value {
        fatalError("Not supported!")
    }

    public var shouldResetOnInsertion: Bool {
        get { return editor.shouldResetOnInsertion }
        set { editor.shouldResetOnInsertion = newValue }
    }

    var textAndInsertionIndex: (text: String, index: String.Index) {
        return editor.textAndInsertionIndex
    }

    func insertCharacter(_ char: Character) {
        editor.insertCharacter(char)
        value[keyPath: keyPath] = editor.value
    }

    func deleteBackward() {
        editor.deleteBackward()
        value[keyPath: keyPath] = editor.value
    }

    func reset() {
        editor.reset()
        value[keyPath: keyPath] = editor.value
    }
}

private final class _AnyTextEditor<Editor: TextEditor>: AnyTextEditor<Editor.Value> {
    public typealias Value = Editor.Value

    public override var defaultValue: Value {
        return editor.defaultValue
    }

    private var editor: Editor

    public init(_ editor: Editor) {
        self.editor = editor
    }

    public override var value: Value {
        get { return editor.value }
        set { editor.value = newValue }
    }

    public override var shouldResetOnInsertion: Bool {
        get { return editor.shouldResetOnInsertion }
        set { editor.shouldResetOnInsertion = newValue }
    }

    public override var textAndInsertionIndex: (text: String, index: String.Index) {
        return editor.textAndInsertionIndex
    }

    public override func insertCharacter(_ char: Character) {
        editor.insertCharacter(char)
    }

    public override func deleteBackward() {
        editor.deleteBackward()
    }

    public override func reset() {
        editor.reset()
    }
}
