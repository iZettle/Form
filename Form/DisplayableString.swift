//
//  DisplayableString.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-12-05.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation
import Flow

/// Conforming types can provide a custom `displayValue` for displaying to end-users.
///
///     struct Localized: DisplayableString {
///       var key: String
///       var displayValue: String { return translate(key) }
///     }
///
///     let label = UILabel(value: Localized("InfoKey"))
///
/// Or if you prefer to be more concise:
///
///     prefix operator §
///     prefix func §(key: String) -> Localized {
///       return Localized(key: key)
///     }
///
///     let label = UILabel(value: §"InfoKey")
///
public protocol DisplayableString: CustomStringConvertible {
    /// The translated value to display to the end-user
    var displayValue: String { get }

    /// An optional identifier used to setup UI controls' accessibility identifier. Defaults to `nil`.
    var accessibilityIdentifier: String? { get }

    /// Extension point to allow adjusting how NSAttributedString is created for a `displayValue` and a `style`.
    /// Defaults to `NSAttributedString(text: displayValue, style: style)`
    func attributedString(using style: TextStyle) -> NSAttributedString
}

public extension DisplayableString {
    var description: String { return displayValue }

    var accessibilityIdentifier: String? { return nil }

    func attributedString(using style: TextStyle) -> NSAttributedString {
        return NSAttributedString(text: displayValue, style: style)
    }
}

public extension DisplayableString {
    var isEmpty: Bool { return displayValue.isEmpty }
}

extension String: DisplayableString {
    public var displayValue: String {
        return self
    }
}

public extension UINavigationItem {
    var displayableTitle: DisplayableString? {
        get {
            return associatedValue(forKey: &titleKey)
        }
        set {
            title = newValue?.displayValue
            setAssociatedValue(newValue, forKey: &titleKey)
            // Never overwrite the accessibilityLabel with nil
            guard let accessibilityLabel = newValue?.displayValue else { return }
            self.accessibilityLabel = accessibilityLabel
        }
    }
}

public extension UIViewController {
    var displayableTitle: DisplayableString? {
        get {
            return navigationItem.displayableTitle ?? associatedValue(forKey: &titleKey)
        }
        set {
            title = newValue?.displayValue
            navigationItem.displayableTitle = newValue
            setAssociatedValue(newValue, forKey: &titleKey)
        }
    }
}

#if canImport(Presentation)
import Presentation

public extension Alert {
    init(title: DisplayableString? = nil, message: DisplayableString? = nil, tintColor: UIColor? = .defaultAlertTintColor, fields: [Field] = [], actions: [Action]) {
        self.init(title: title?.displayValue, message: message?.displayValue, tintColor: tintColor, fields: fields, actions: actions)
    }

    init(title: DisplayableString? = nil, message: DisplayableString? = nil, tintColor: UIColor? = .defaultAlertTintColor, fields: [Field] = [], actions: Action...) {
        self.init(title: title, message: message, tintColor: tintColor, fields: fields, actions: actions)
    }
}

public extension Alert.Action {
    init(title: DisplayableString, style: UIAlertAction.Style = .default, enabledPredicate: @escaping ([String]) -> Bool = { _ in true }, action: @escaping ([String]) throws -> Value) {
        self.init(title: title.displayValue, style: style, enabledPredicate: enabledPredicate, action: action)
    }

    init(title: DisplayableString, style: UIAlertAction.Style = .default, action: @escaping () throws -> Value) {
        self.init(title: title, style: style, action: { (_: [String]) in try action() })
    }
}

public extension Alert.Field {
    init(initial: String = "", style: FieldStyle = .default) {
        self.init(initial: initial) { $0.style = style }
    }
}

#endif

private var titleKey: UInt8 = 0
