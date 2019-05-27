//
//  ValueField.swift
//  Flow
//
//  Created by Måns Bernhardt on 2016-02-16.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A field being generic on `Value` using a `TextEditor` for editing and cursor placement.
///
///     let editor = ValueEditor(value: 0, isValidCharacter: isDigit)
///     let field = ValueField(value: 4711, editor: editor)
///
/// - Note: There is no support for moving the cursor and working with selections.
public final class ValueField<Value>: UIControl, UIKeyInput {
    private var editor: AnyTextEditor<Value>
    private let label: UILabel
    private let placeholderLabel: UILabel
    private let cursor: UIView
    private var _inputView: UIView?
    private var _inputViewController: UIInputViewController?
    private let bag = DisposeBag()

    private var cursorConstraint: NSLayoutConstraint!

    private var leftTextAlignmentConstraints: [NSLayoutConstraint]!
    private var rightTextAlignmentConstraints: [NSLayoutConstraint]!

    private var leftPlaceholderAlignmentConstraints: [NSLayoutConstraint]!
    private var rightPlaceholderAlignmentConstraints: [NSLayoutConstraint]!

    public var style: FieldStyle {
        didSet { applyStyle() }
    }

    public init<Editor: TextEditor>(value: Value, placeholder: DisplayableString = "", editor: Editor, style: FieldStyle = .default) where Editor.Value == Value {
        self.editor = editor.anyEditor
        self.editor.value = value
        self.style = style

        label = UILabel(value: editor.text, style: style.text)
        label.baselineAdjustment = .none

        placeholderLabel = UILabel(value: placeholder.displayValue, style: style.placeholder)
        placeholderLabel.isHidden = true

        cursor = UIView()
        cursor.isHidden = true
        cursor.layer.cornerRadius = 1
        cursor.layer.opacity = 0
        cursor.backgroundColor = style.cursorColor

        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = placeholder.accessibilityIdentifier
        accessibilityLabel = placeholder.displayValue

        cursorConstraint = label.trailingAnchor == cursor.trailingAnchor

        let constraints: [NSLayoutConstraint] = [
            label.topAnchor == topAnchor,
            label.bottomAnchor == bottomAnchor,
            placeholderLabel.topAnchor == topAnchor,
            placeholderLabel.bottomAnchor == bottomAnchor,
            cursor.topAnchor == topAnchor,
            cursor.bottomAnchor == bottomAnchor,
            cursorConstraint!,
            placeholderLabel.leadingAnchor == leadingAnchor + 1,
            cursor.widthAnchor == 2
        ]

        leftTextAlignmentConstraints = [
            label.leftAnchor == leftAnchor,
            label.rightAnchor <= rightAnchor,
        ] as [NSLayoutConstraint]

        rightTextAlignmentConstraints = [
            label.leftAnchor >= leftAnchor,
            label.rightAnchor == rightAnchor,
        ] as [NSLayoutConstraint]

        leftPlaceholderAlignmentConstraints = [
            placeholderLabel.leftAnchor == leftAnchor,
            placeholderLabel.rightAnchor <= rightAnchor,
        ] as [NSLayoutConstraint]

        rightPlaceholderAlignmentConstraints = [
            placeholderLabel.leftAnchor >= leftAnchor,
            placeholderLabel.rightAnchor == rightAnchor,
        ] as [NSLayoutConstraint]

        // Placeholder
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)

        // Label
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        // Cursor
        addSubview(cursor)
        cursor.translatesAutoresizingMaskIntoConstraints = false

        activate(constraints)
        activate(leftTextAlignmentConstraints + rightTextAlignmentConstraints)
        activate(leftPlaceholderAlignmentConstraints + rightPlaceholderAlignmentConstraints)

        applyStyle()
        updateText()

        bag += NotificationCenter.default.signal(forName: UIApplication.didBecomeActiveNotification).with(weak: self).onValue { _, `self` in
            self.installAnimation() // When app is deactivated, running animations are removed. Let's re-install it.
        }

        let longPressGesture = UILongPressGestureRecognizer()
        addGestureRecognizer(longPressGesture)
        bag += longPressGesture.signal(forState: .began).with(weak: self).onValue { `self` in
            let menuController = UIMenuController.shared
            menuController.setTargetRect(self.bounds, in: self)
            menuController.setMenuVisible(true, animated: true)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isEnabled: Bool {
        didSet { applyStyle() }
    }

    public override var accessibilityValue: String? {
        get { return label.text }
        set {
            guard let text = newValue else { return }
            label.value = text
        }
    }

    public override var inputView: UIView? {
        get { return _inputView }
        set { _inputView = newValue }
    }

    public override var inputViewController: UIInputViewController? {
        get { return _inputViewController }
        set { _inputViewController = newValue }
    }

    public dynamic var returnKeyType: UIReturnKeyType = .default

    /// Always use `.no` autocorrection as the system keyboard will be confused if it is used.
    public dynamic var autocorrectionType: UITextAutocorrectionType {
        get { return .no }
        //swiftlint:disable:next unused_setter_value
        set { /* ignore */ }
    }

    public dynamic var keyboardType: UIKeyboardType = .default

    public override var intrinsicContentSize: CGSize {
        return editor.text.isEmpty ? placeholderLabel.intrinsicContentSize : label.intrinsicContentSize
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isEnabled && !isFirstResponder {
            sendActions(for: .editingDidBegin)
            _ = becomeFirstResponder()
        }
    }

    public override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else { return false }

        cursor.isHidden = false
        installAnimation()
        sendActions(for: .editingDidBegin)
        NotificationCenter.default.post(name: UITextField.textDidBeginEditingNotification, object: self)

        return true
    }

    public override func resignFirstResponder() -> Bool {
        guard super.resignFirstResponder() else { return false }

        cursor.isHidden = true
        editor.value = editor.value
        updateText()
        sendActions(for: .editingDidEnd)
        NotificationCenter.default.post(name: UITextField.textDidEndEditingNotification, object: self)

        return true
    }

    public override var canBecomeFirstResponder: Bool { return isEnabled }

    public override func copy(_ sender: Any?) {
        UIPasteboard.general.string = editor.text
    }

    public override func paste(_ sender: Any?) {
        editor.insertText(UIPasteboard.general.string ?? "")
        updateText()
    }

    /// MARK: UIKeyInput (compiler complains if moved to separate extension)

    public var hasText: Bool {
        return !editor.text.isEmpty
    }

    public func insertText(_ text: String) {
        for char in text {
            switch char {
            case "\n":
                sendActions(for: .editingDidEndOnExit)
            case "\t":
                sendActions(for: .editingDidEndOnExit)
            default:
                editor.insertCharacter(char)
            }
        }

        updateText()
    }

    public func deleteBackward() {
        editor.deleteBackward()
        updateText()
    }
}

public extension ValueField {
    var minimumScaleFactor: CGFloat? {
        get { return label.adjustsFontSizeToFitWidth ? label.minimumScaleFactor : nil }
        set {
            if let factor = newValue {
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = factor
            } else {
                label.adjustsFontSizeToFitWidth = false
            }
        }
    }

    var baselineAdjustment: UIBaselineAdjustment {
        get { return label.baselineAdjustment }
        set { label.baselineAdjustment = newValue }
    }
}

extension ValueField: SignalProvider {
    public var providedSignal: ReadWriteSignal<Value> {
        return signal(for: .editingChanged).readable().map { self.value }.writable { self.value = $0 }
    }
}

public extension ValueField {
    convenience init<Editor: TextEditor>(value: Value, keyPath: WritableKeyPath<Value, Editor.Value>, placeholder: DisplayableString = "", editor: Editor, style: FieldStyle = .default) {
        let editor = KeyPathTextEditor(value: value, keyPath: keyPath, editor: editor)
        self.init(value: value, placeholder: placeholder, editor: editor, style: style)
    }
}

public extension ValueField where Value: BinaryInteger {
    convenience init(value: Value, placeholder: DisplayableString = "", style: FieldStyle = .numeric, formatter: NumberFormatter = .defaultInteger) {
        self.init(value: value, placeholder: placeholder, editor: NumberEditor(formatter: formatter), style: style)
    }
}

public extension ValueField where Value: BinaryFloatingPoint & CustomStringConvertible {
    convenience init(value: Value, placeholder: DisplayableString = "", style: FieldStyle = .decimal, formatter: NumberFormatter = .defaultDecimal) {
        self.init(value: value, placeholder: placeholder, editor: NumberEditor(formatter: formatter), style: style)
    }
}

private extension ValueField {
    var value: Value {
        get { return editor.value }
        set {
            editor.value = newValue
            updateText()
        }
    }

    func applyStyle() {
        label.style = isEnabled ? style.text : style.disabled
        placeholderLabel.style = style.placeholder
        cursor.backgroundColor = style.cursorColor
        returnKeyType = style.returnKey
        keyboardType = style.keyboard
        updateAlignmentConstraints()
    }

    func updateText() {
        let (text, insertionIndex) = editor.textAndInsertionIndex
        label.value = text

        label.isHidden = text.isEmpty
        placeholderLabel.isHidden = !text.isEmpty

        updateAlignmentConstraints()

        // Use the editors inserionIndex to calculate where to place the cursor
        let trailingText = String(text[insertionIndex..<text.endIndex])
        let context = NSStringDrawingContext()
        context.minimumScaleFactor = label.minimumScaleFactor
        let trailingRect = trailingText.boundingRect(with: CGSize(width: 0, height: 0), options: [], attributes: style.text.attributes, context: context)
        cursorConstraint.constant = trailingRect.width - 1
        invalidateIntrinsicContentSize()

        sendActions(for: .editingChanged)
        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: self)
    }

    func updateAlignmentConstraints() {
        leftTextAlignmentConstraints.forEach { $0.isActive = style.text.alignmentResolvingNatural != .right }
        rightTextAlignmentConstraints.forEach { $0.isActive = style.text.alignmentResolvingNatural != .left }
        leftPlaceholderAlignmentConstraints.forEach { $0.isActive = style.placeholder.alignmentResolvingNatural != .right && editor.text.isEmpty }
        rightPlaceholderAlignmentConstraints.forEach { $0.isActive = style.placeholder.alignmentResolvingNatural != .left && editor.text.isEmpty }
    }

    func installAnimation() {
        cursor.layer.removeAnimation(forKey: "flash")
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0, 1, 1, 0, 0]
        animation.keyTimes = [0, 0.2, 0.6, 0.8, 1.0]
        animation.duration = 1.2
        animation.calculationMode = CAAnimationCalculationMode.cubic
        animation.repeatCount = Float.infinity
        cursor.layer.add(animation, forKey: "flash")
    }
}

private extension TextStyle {
    var alignmentResolvingNatural: NSTextAlignment {
        guard alignment == .natural else { return alignment }
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .right : .left
    }
}
