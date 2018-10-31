//
//  TextStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-25.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit
import Flow

public struct TextStyle: Style {
    fileprivate var changeIndex: Int = 0
    private var extraAttributes = Set<NSAttributedStringKey>()
    fileprivate var customAttributes = Set<NSAttributedStringKey>()

    public typealias Attributes = [NSAttributedStringKey: Any]
    public private(set) var attributes: Attributes = [:]
}

public extension TextStyle {
    public init(font: UIFont, color: UIColor, alignment: NSTextAlignment = .natural, numberOfLines: Int = 1, lineBreakMode: NSLineBreakMode = .byTruncatingMiddle) {
        // Don't set attributes directly to make sure lookups such as equatableForAttribute is being correctly updated.
        self.font = font
        self.color = color
        self.numberOfLines = numberOfLines
        self.alignment = alignment
        self.lineBreakMode = lineBreakMode
    }
}

public extension TextStyle {
    var font: UIFont {
        get { return attribute(for: .font)! } // Initializer guarantees we always have a font
        set { setAttribute(newValue, for: .font) }
    }

    var color: UIColor {
        get { return attribute(for: .foregroundColor)! }  // Initializer guarantees we always have a color
        set { setAttribute(newValue, for: .foregroundColor) }
    }

    var alignment: NSTextAlignment {
        get { return attribute(for: .textAlignment) ?? .natural }
        set { setParagraphAttribute(newValue, for: .textAlignment, defaultValue: .natural) { $0.alignment = newValue } }
    }

    var lineBreakMode: NSLineBreakMode {
        get { return attribute(for: .lineBreakMode) ?? .byTruncatingTail }
        set { setParagraphAttribute(newValue, for: .lineBreakMode, defaultValue: .byTruncatingTail) { $0.lineBreakMode = newValue } }
    }

    var lineSpacing: CGFloat {
        get { return attribute(for: .lineSpacing) ?? 0 }
        set { setParagraphAttribute(newValue, for: .lineSpacing, defaultValue: 0) { $0.lineSpacing = newValue } }
    }

    var kerning: Float {
        get { return attribute(for: .kern) ?? 0 }
        set { setAttribute(newValue, for: .kern, defaultValue: 0) }
    }

    var numberOfLines: Int {
        get { return attribute(for: .numberOfLines) ?? 1 }
        set { setAttribute(newValue == 1 ? nil : newValue, for: .numberOfLines) }
    }

    var highlightedColor: UIColor {
        get { return attribute(for: .highlightedColor) ?? self.color }
        set { setAttribute(newValue, for: .highlightedColor) }
    }
}

public extension TextStyle {
    static let system = prototypeLabel.style
    static var `default`: TextStyle { return DefaultStyling.current.text }

    static let systemDetail = prototypeCell.detailTextLabel?.style ?? TextStyle.system.colored(UIColor(white: 0.6, alpha: 1))
    static var defaultDetail: TextStyle { return DefaultStyling.current.detailText }
}

public extension TextStyle {
    func attribute<T>(for attribute: NSAttributedStringKey) -> T? {
        return attributes[attribute] as? T
    }

    mutating func setAttribute<T: Equatable>(_ value: T?, for attribute: NSAttributedStringKey, defaultValue: T? = nil) {
        guard self.attribute(for: attribute) != value else {
            return
        }

        if let defaultValue = defaultValue, value == defaultValue {
            attributes[attribute] = nil
        } else {
            attributes[attribute] = value
            if equatableForAttribute[attribute] == nil {
                equatableForAttribute[attribute] = { $0 as! T == $1 as! T }
            }
        }

        changeIndex = nextTextStyleChangeIndex
        nextTextStyleChangeIndex += 1

        guard !plainAttributes.contains(attribute) else {
            return
        }

        guard Form.customAttributes[attribute] == nil else {
            if value == nil {
                customAttributes.remove(attribute)
            } else {
                customAttributes.insert(attribute)
            }
            return
        }

        if value == nil {
            extraAttributes.remove(attribute)
        } else {
            extraAttributes.insert(attribute)
        }
    }

    mutating func setParagraphAttribute<T: Equatable>(_ value: T?, for attribute: NSAttributedStringKey, defaultValue: T? = nil, update: (inout NSMutableParagraphStyle) -> ()) {
        guard self.attribute(for: attribute) != value else {
            return
        }

        if let defaultValue = defaultValue, value == defaultValue, self.attribute(for: .paragraphStyle) == nil {
            setAttribute(nil as T?, for: attribute)
            return
        }

        setAttribute(value, for: attribute)

        var style = ((self.attribute(for: .paragraphStyle) as NSParagraphStyle?)?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
        update(&style)
        attributes[.paragraphStyle] = style
    }

    /// Register a custom `transfrom` for `attribute`
    /// Custom transforms could be used to apply transforms on the styled text. The transforms are typlically applied after ordinary styling.
    /// For example `.uppercased`, etc. are built using custom transforms.
    static func registerCustomTransform(for attribute: NSAttributedStringKey, transform: @escaping (NSAttributedString, Any) -> NSAttributedString) {
        precondition(Form.customAttributes[attribute] == nil)
        Form.customAttributes[attribute] = transform
    }
}

extension TextStyle: Equatable {
    public static func == (lhs: TextStyle, rhs: TextStyle) -> Bool {
        // fast-path
        guard lhs.changeIndex != rhs.changeIndex else {
            return true
        }

        guard lhs.attributes.count == rhs.attributes.count else {
            return false
        }

        for (attribute, left) in lhs.attributes {
            guard let right = rhs.attributes[attribute], attribute != .paragraphStyle else {
                return false
            }

            let isSame = equatableForAttribute[attribute]!

            guard isSame(left, right) else {
                return false
            }
        }

        return true
    }
}

public extension NSAttributedString {
    convenience init(text: String, style: TextStyle) {
        let attr = NSAttributedString(string: text, attributes: style.attributes)

        guard let custom = style.applyCustomAttributes(to: attr) else {
            self.init(attributedString: attr)
            return
        }

        self.init(attributedString: custom)
    }

    convenience init(text: DisplayableString, style: TextStyle) {
        let attr = text.attributedString(using: style)

        guard let custom = style.applyCustomAttributes(to: attr) else {
            self.init(attributedString: attr)
            return
        }

        self.init(attributedString: custom)
    }

    convenience init(styledText: StyledText) {
        self.init(text: styledText.text, style: styledText.style)
    }
}

/// A composition of a `DisplayableString` and `TextStyle`.
public struct StyledText {
    public var text: DisplayableString
    public var style: TextStyle

    public init(text: DisplayableString, style: TextStyle) {
        self.text = text
        self.style = style
    }
}

public extension StyledText {
    func restyled(_ styler: (inout TextStyle) -> ()) -> StyledText {
        return StyledText(text: text, style: style.restyled(styler))
    }
}

/// A composition of a text, placeholder and `FieldStyle`.
public struct StyledFieldText {
    public var text: DisplayableString
    public var placeholder: DisplayableString
    public var style: FieldStyle

    public init(text: DisplayableString, placeholder: DisplayableString, style: FieldStyle) {
        self.text = text
        self.placeholder = placeholder
        self.style = style
    }
}

extension NSAttributedStringKey {
    static let numberOfLines = NSAttributedStringKey(rawValue: "_numberOfLines")
    static let highlightedColor = NSAttributedStringKey(rawValue: "_highlightedColor")
    static let lineBreakMode = NSAttributedStringKey(rawValue: "_lineBreakMode")
    static let lineSpacing = NSAttributedStringKey(rawValue: "_lineSpacing")
    static let textAlignment = NSAttributedStringKey(rawValue: "_textAligment")
}

extension TextStyle {
    var isPlain: Bool {
        return extraAttributes.isEmpty && customAttributes.isEmpty
    }
}

extension TextStyle {
    init(attributes: [String: Any]) {
        for (key, value) in attributes {
            let attribute = NSAttributedStringKey(rawValue: key)
            self.attributes[attribute] = value
            guard !plainAttributes.contains(attribute) else {
                continue
            }
            extraAttributes.insert(attribute)
        }

        precondition(self.attributes[.font] != nil)
        precondition(self.attributes[.foregroundColor] != nil)
    }
}

private extension TextStyle {
    func applyCustomAttributes(to string: NSAttributedString) -> NSAttributedString? {
        guard !customAttributes.isEmpty else { return nil }

        return attributes.reduce(string) { string, attribute in
            Form.customAttributes[attribute.key]?(string, attribute.value) ?? string
        }
    }
}

private var equatableForAttribute = [NSAttributedStringKey: (Any, Any) -> Bool]()
private var nextTextStyleChangeIndex = 0
private let plainAttributes: Set<NSAttributedStringKey> = [.foregroundColor, .font, .numberOfLines, .highlightedColor, .lineBreakMode, .textAlignment]
private var customAttributes = [NSAttributedStringKey: ((NSAttributedString, Any) -> NSAttributedString)]()

private let prototypeCell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: nil)
private let prototypeLabel = UILabel(frame: .zero)
