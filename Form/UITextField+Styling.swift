//
//  UITextField+Styling.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-10-16.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UITextField {
    convenience init(styledFieldText: StyledFieldText) {
        self.init(frame: CGRect.zero)

        styledText = StyledText(text: styledFieldText.text, style: styledFieldText.style.text)
        styledPlaceholder = StyledText(text: styledFieldText.placeholder, style: styledFieldText.style.placeholder)
        style = styledFieldText.style

        accessibilityIdentifier = styledFieldText.placeholder.accessibilityIdentifier
        accessibilityLabel = styledFieldText.placeholder.displayValue
    }

    convenience init(value: DisplayableString = "", placeholder: DisplayableString = "", style: FieldStyle = .default) {
        self.init(styledFieldText: StyledFieldText(text: value, placeholder: placeholder, style: style))
    }
}

public extension UITextField {
    /// The current text.
    /// - Note: It is advised to use `value` instead of `text` to not accidentically break styling
    var value: String {
        get { return text ?? "" }
        set { text = newValue }
    }

    /// The current text style.
    /// - Note: It is advised to use `value` instead of `text` to not accidentically break styling
    var style: FieldStyle {
        get {
            return associatedValue(forKey: &styleKey, initial: FieldStyle(textField: self))
        }
        set {
            setAssociatedValue(newValue, forKey: &styleKey)

            let selectedTextRange = self.selectedTextRange // selection gets reset after style update

            font = newValue.text.font
            textColor = newValue.text.color
            textAlignment = newValue.text.alignment
            tintColor = newValue.cursorColor
            autocorrectionType = newValue.autocorrection
            autocapitalizationType = newValue.autocapitalization
            keyboardType = newValue.keyboard
            clearButtonMode = newValue.clearButton
            returnKeyType = newValue.returnKey

            let styledText = StyledText(text: text ?? "", style: newValue.text)
            attributedText = NSAttributedString(styledText: styledText)
            attributedPlaceholder = NSAttributedString(text: placeholder ?? "", style: newValue.placeholder)

            if #available(iOS 10.0, *) {
                self.refreshTextScaling(for: newValue.text)
            }

            textAlignment = newValue.text.alignment

            self.selectedTextRange = selectedTextRange

            // Never overwrite the accessibilityIdentifier with nil
            guard let accessibilityIdentifier = styledText.text.accessibilityIdentifier else { return }
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    var styledText: StyledText {
        get {
            return StyledText(text: self.text ?? "", style: self.style.text)
        }
        set {
            text = newValue.text.displayValue
            style.text = newValue.style
        }
    }

    var styledPlaceholder: StyledText {
        get {
            return StyledText(text: self.placeholder ?? "", style: self.style.placeholder)
        }
        set {
            placeholder = newValue.text.displayValue
            style.placeholder = newValue.style
        }
    }
}

extension FieldStyle {
    init(textField: UITextField) {
        text = TextStyle(font: textField.font ?? .systemFont(ofSize: 12), color: textField.textColor ?? .black, alignment: textField.textAlignment)
        placeholder = text.colored(UIColor(white: 0.8, alpha: 1))
        disabled = text.colored(UIColor(white: 0.4, alpha: 1))
        cursorColor = UIColor(red: 0, green: 0.42, blue: 0.9, alpha: 1)
        autocorrection = textField.autocorrectionType
        autocapitalization = textField.autocapitalizationType
        clearButton = textField.clearButtonMode
        keyboard = textField.keyboardType
        returnKey = textField.returnKeyType
    }
}

private var styleKey = 0
