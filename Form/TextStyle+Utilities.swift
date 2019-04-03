//
//  TextStyle+Utilities.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-10-16.
//  Copyright © 2017 iZettle. All rights reserved.
//

import Foundation

public extension TextStyle {
    /// Returns a restyled instance using `color`
    func colored(_ color: UIColor) -> TextStyle {
        return restyled { $0.color = color }
    }

    /// Returns a restyled instance with a `color` using `alpha`.
    func alphaColored(_ alpha: CGFloat) -> TextStyle {
        return colored(color.withAlphaComponent(alpha))
    }

    /// Returns a restyled instance aligned to `alignment`.
    func aligned(to alignment: NSTextAlignment) -> TextStyle {
        return restyled { $0.alignment = alignment }
    }

    /// Returns a restyled instance aligned to left.
    var leftAligned: TextStyle {
        return aligned(to: .left)
    }

    /// Returns a restyled instance aligned to right.
    var rightAligned: TextStyle {
        return aligned(to: .right)
    }

    /// Returns a restyled instance aligned to center.
    var centerAligned: TextStyle {
        return aligned(to: .center)
    }

    /// Returns a restyled instance with `font` resized to `pointSize`.
    func resized(to pointSize: CGFloat) -> TextStyle {
        return restyled { $0.font = UIFont(descriptor: $0.font.fontDescriptor, size: pointSize) }
    }

    /// Returns a restyled instance with `lineBreakMode` set to `.byTruncatingMiddle`.
    var truncatedMiddle: TextStyle {
        return restyled { $0.lineBreakMode = .byTruncatingMiddle }
    }

    /// Returns a restyled instance with `lineBreakMode` set to `.byTruncatingTail`.
    var truncatedTail: TextStyle {
        return restyled { $0.lineBreakMode = .byTruncatingTail }
    }

    /// Returns a restyled instance with `lineBreakMode` set to `.byWordWrapping`.
    var wordWrapped: TextStyle {
        return restyled { $0.lineBreakMode = .byWordWrapping }
    }

    /// Sets `numberOfLines`  to `lines` and `lineBreakMode` to `lineBreakMode`.
    mutating func setMultilined(lines: Int = 0, lineBreakMode: NSLineBreakMode = .byWordWrapping) {
        self.numberOfLines = lines
        self.lineBreakMode = lineBreakMode
    }

    /// Returns a restyled instance with `numberOfLines` set to `lines` and `lineBreakMode` to `lineBreakMode`.
    func multilined(lines: Int = 0, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> TextStyle {
        return restyled { $0.setMultilined(lines: lines, lineBreakMode: lineBreakMode) }
    }
}

public enum TextCase: Int {
    case preserve, lower, upper, capitalized
}

public extension TextStyle {
    var textCase: TextCase {
        get { return (attribute(for: .textCase) as Int?).flatMap { TextCase(rawValue: $0) } ?? .preserve }
        set { setAttribute(newValue.rawValue, for: .textCase) }
    }

    /// Returns a restyled instance with `textCase` set to `.preserve`.
    var preservedCasing: TextStyle { return restyled { $0.textCase = .preserve } }

    /// Returns a restyled instance with `textCase` set to `.upper`.
    var uppercased: TextStyle { return restyled { $0.textCase = .upper } }

    /// Returns a restyled instance with `textCase` set to `.lower`.
    var lowercased: TextStyle { return restyled { $0.textCase = .lower } }

    /// Returns a restyled instance with `textCase` set to `.capitalized`.
    var capitalized: TextStyle { return restyled { $0.textCase = .capitalized } }
}

extension NSAttributedString.Key {
    public static let textCase: NSAttributedString.Key = {
        let attribute = NSAttributedString.Key(rawValue: "TextCaseAttributeName")
        TextStyle.registerCustomTransform(for: attribute) { string, argument in
            guard let stringCaseRaw: Int = argument as? Int, let stringCase = TextCase(rawValue: stringCaseRaw) else { return string }
            switch stringCase {
            case .preserve: return string
            case .lower: return string.map { $0.localizedLowercase }
            case .upper: return string.map { $0.localizedUppercase }
            case .capitalized: return string.map { $0.capitalized }
            }
        }
        return attribute
    }()
}

private extension NSAttributedString {
    func map(_ transform: (String) -> String) -> NSAttributedString {
        let result = NSMutableAttributedString()

        self.enumerateAttributes(in: NSRange(location: 0, length: self.string.count), options: []) { attributes, range, _ in
            let substring = (self.string as NSString).substring(with: range)
            result.append(NSAttributedString(string: transform(substring), attributes: attributes))
        }

        return result
    }
}
