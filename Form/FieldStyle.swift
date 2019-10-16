//
//  FieldStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-10-16.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

public struct FieldStyle: Style {
    public var text: TextStyle
    public var placeholder: TextStyle
    public var disabled: TextStyle
    public var cursorColor: UIColor
    public var autocorrection: UITextAutocorrectionType = .default
    public var autocapitalization: UITextAutocapitalizationType = .sentences
    public var clearButton: UITextField.ViewMode = .never
    public var keyboard: UIKeyboardType = .default
    public var returnKey: UIReturnKeyType = .done
}

public extension FieldStyle {
    init(text: TextStyle, placeholder: TextStyle, disabled: TextStyle, cursorColor: UIColor) {
        self.text = text
        self.placeholder = placeholder
        self.disabled = disabled
        self.cursorColor = cursorColor
    }
}

public extension FieldStyle {
    static let system = FieldStyle(textField: prototypeTextField)
    static var `default`: FieldStyle { return DefaultStyling.current.field }

    /// Default style setup for editing urls.
    static var email: FieldStyle { return `default`.email }

    /// Default style setup for editing emails.
    static var url: FieldStyle { return `default`.url }

    /// Default style setup for editing numbers.
    static var numeric: FieldStyle { return `default`.numeric }

    /// Default style setup for editing decimals.
    static var decimal: FieldStyle { return `default`.decimal }
}

public extension FieldStyle {
    /// Returns a new style with `autocorrection` set to `autocorrection`.
    func autocorrected(_ autocorrection: UITextAutocorrectionType) -> FieldStyle {
        return restyled { $0.autocorrection = autocorrection }
    }

    /// Returns a new style with `autocapitalization` set to `autocapitalization`.
    func autocapitalized(_ autocapitalization: UITextAutocapitalizationType) -> FieldStyle {
        return restyled { $0.autocapitalization = autocapitalization }
    }

    /// Returns new style adjusted with clearButton set to `mode`.
    func clearButton(_ mode: UITextField.ViewMode) -> FieldStyle {
        return restyled { $0.clearButton = mode }
    }

    /// Returns new style adjusted with returnKey set to `type`.
    func returnKey(_ type: UIReturnKeyType) -> FieldStyle {
        return restyled { $0.returnKey = type }
    }

    /// Returns new style adjusted with keyboard set to `type`.
    func keyboard(_ type: UIKeyboardType) -> FieldStyle {
        return restyled { $0.keyboard = type }
    }

    /// Returns new style adjusted for editing urls with no autocorrection nor autocapitalization.
    var email: FieldStyle {
        return restyled { style in
            style.autocorrection = .no
            style.autocapitalization =  .none
            style.keyboard = .emailAddress
        }
    }

    /// Returns new style adjusted for editing urls with no autocorrection nor autocapitalization.
    var url: FieldStyle {
        return restyled { style in
            style.autocorrection = .no
            style.autocapitalization =  .none
            style.keyboard = .URL
        }
    }

    /// Returns new style adjusted for editing numbers.
    /// - Note: Keyboard set to `.numberPad` on iPhone or `.numbersAndPunctuation` on iPad.
    var numeric: FieldStyle {
        return restyled { $0.keyboard = .numeric }
    }

    /// Returns new style adjusted for editing decimals.
    /// - Note: Keyboard set to `.numbersAndPunctuation`
    var decimal: FieldStyle {
        return restyled { $0.keyboard = .decimal }
    }
}

public extension UIKeyboardType {
    /// `.numberPad` if iPhone or `.numbersAndPunctuation` if iPad.
    static var numeric: UIKeyboardType { return (UIApplication.shared.keyWindow?.traitCollection.horizontalSizeClass == .regular) ? .numbersAndPunctuation : .numberPad }
    /// `.numbersAndPunctuation`
    static let decimal: UIKeyboardType = .numbersAndPunctuation
}

private let prototypeTextField = UITextField(frame: .zero)
