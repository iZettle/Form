//
//  UILabel+Styling.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-10-16.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UILabel {
    convenience init(styledText: StyledText) {
        self.init()
        setContentHuggingPriority(.required, for: .horizontal)
        setStyledText(styledText)
    }

    convenience init(value: DisplayableString = "", style: TextStyle = .default) {
        self.init(styledText: StyledText(text: value, style: style))
    }
}

public extension UILabel {
    /// The current text as `DisplayableString`.
    /// - Note: It is advised to use `value` instead of `text` to not accidentically break styling
    var value: DisplayableString {
        get { return styledText.text }
        set { styledText.text = newValue }
    }

    /// The current text style.
    /// - Note: It is advised to use `value` instead of `text` to not accidentically break styling
    var style: TextStyle {
        get { return styledText.style }
        set {
            guard associatedValue(forKey: &styledTextKey) as StyledText? != nil else { // Avoid creating initial style.
                styledText = StyledText(text: text ?? "", style: newValue)
                return
            }

            styledText.style = newValue
        }
    }

    var styledText: StyledText {
        get {
            return associatedValue(forKey: &styledTextKey, initial: StyledText(text: text ?? "", style: TextStyle(font: font, color: textColor, alignment: textAlignment, lineBreakMode: lineBreakMode)))
        }
        set {
            setStyledText(newValue)
        }
    }
}

private extension UILabel {
    func setStyledText(_ styledText: StyledText) {
        let prevStyledText: StyledText? = associatedValue(forKey: &styledTextKey)
        setAssociatedValue(styledText, forKey: &styledTextKey)

        let style = styledText.style
        if let prev = prevStyledText, style == prev.style {
            // No update needed
        } else {
            if font != style.font {
                font = style.font
            }
            textColor = style.color
            highlightedTextColor = style.highlightedColor

            numberOfLines = style.numberOfLines
            textAlignment = style.alignment
            lineBreakMode = style.lineBreakMode
        }

        let displayValue = styledText.text.displayValue
        if style.isPlain {
            text = displayValue
        } else if let prev = prevStyledText, displayValue == prev.text.displayValue, style == prev.style {
            // No update needed
        } else {
            attributedText = NSAttributedString(styledText: styledText)
        }

        guard let accessibilityIdentifier = styledText.text.accessibilityIdentifier else { return }
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

private var styledTextKey = 0
