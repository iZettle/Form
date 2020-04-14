//
//  NumberEditor.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-25.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

/// A number (potentially with decimals) editor that tries to respect the provided NumberFormatter settings.
/// If the formatter has minimumFractionDigits > 0 it will use the "cash register" kind of input, otherwise "calculator" mode will be used.
public struct NumberEditor<Value> {
    private var formatterBox: Box<NumberFormatter> // Need to box the formatter to assure we respect value semantics
    private var minFractionDigits: Int // If greater than zero, "cash register" will be used
    private var internalText: String // The internal text is just a string of digits [0-9].
    private var isNegative: Bool = false
    private let valueToDecimal: (Value) -> NSDecimalNumber
    private let decimalToValue: (NSDecimalNumber) -> Value

    public var shouldResetOnInsertion: Bool = false
    public let defaultValue: Value

    /// Creates a new instance with using `formatter` settings for editing.
    /// Parameters:
    ///   - valueToDecimal: How to convert a `Value` to a decimal number.
    ///   - decimalToValue: How to convert a decimal number back to a `Value`.
    public init(formatter: NumberFormatter, valueToDecimal: @escaping (Value) -> NSDecimalNumber, decimalToValue: @escaping (NSDecimalNumber) -> Value) {
        let formatter = formatter.copy
        formatter.generatesDecimalNumbers = true
        minFractionDigits = formatter.minimumFractionDigits
        formatterBox = Box(formatter)

        self.defaultValue = decimalToValue(0)
        self.internalText = "0"

        self.valueToDecimal = valueToDecimal
        self.decimalToValue = decimalToValue
    }
}

extension NumberEditor: TextEditor {
    public var value: Value {
        get { return decimalToValue(decimalFromInternalText) }
        set { updateInternalText(from: valueToDecimal(newValue)) }
    }

    public var textAndInsertionIndex: (text: String, index: String.Index) {
        let text = formatter.string(from: decimalFromInternalText(internalText))!

        guard let insertionIndexFromBack = formatter.insertionIndexFromBack else { return (text, text.endIndex) }
        return (text, text.index(text.endIndex, offsetBy: -insertionIndexFromBack))
    }

    mutating public func insertCharacter(_ char: Character) {
        let maxLength = formatter.maximumIntegerDigits + minimumFractionDigits

        guard internalText.count < maxLength || char == decimalCharacter || (alwaysShowsDecimalSeparator && minFractionDigits == 0) else {
            return
        }

        let insertStr = String(char)

        if formatter.maximumFractionDigits > 0 && char == decimalCharacter {
            alwaysShowsDecimalSeparator = true
        } else if Int(insertStr) != nil {
            if minFractionDigits <= 0 && formatter.maximumFractionDigits > 0 { // Rewrite guard
                guard minimumFractionDigits < formatter.maximumFractionDigits else { return }

                if alwaysShowsDecimalSeparator {
                    minimumFractionDigits += 1
                }
            }

            if shouldResetOnInsertion {
                shouldResetOnInsertion = false
                reset()
            }

            append(char)
        } else if char == negativeCharacter,
            formatter.minimum?.decimalValue.isSignMinus ?? true {
            isNegative = !isNegative
        }
    }

    mutating public func deleteBackward() {
        if minFractionDigits <= 0 {
            if minimumFractionDigits > 0 {
                minimumFractionDigits -= 1
            } else if alwaysShowsDecimalSeparator {
                alwaysShowsDecimalSeparator = false
                return
            }
        }

        shouldResetOnInsertion = false
        deleteLast()
    }
}

public extension NumberEditor where Value == NSDecimalNumber {
    init(formatter: NumberFormatter) {
        self.init(formatter: formatter, valueToDecimal: { $0 }, decimalToValue: { $0 })
    }
}

public extension NumberEditor where Value: BinaryInteger {
    init(formatter: NumberFormatter = .defaultInteger) {
        precondition(formatter.maximumFractionDigits == 0, "formatter used for integers must have maximumFractionDigits == 0")
        self.init(formatter: formatter,
                  valueToDecimal: { NSDecimalNumber(value: Int64($0)) },
                  decimalToValue: { Value(truncatingIfNeeded: $0.uint64Value) })
    }
}

public extension NumberEditor where Value: BinaryFloatingPoint & CustomStringConvertible {
    init(formatter: NumberFormatter = .defaultDecimal) {
        self.init(formatter: formatter,
                  valueToDecimal: { NSDecimalNumber(value: Double($0.description) ?? .nan) },
                  decimalToValue: { Value($0.doubleValue) })
    }
}

public extension NumberFormatter {
    static var defaultInteger: NumberFormatter { return integerFormatter.copy }
    static var defaultDecimal: NumberFormatter { return decimalFormatter.copy }
}

private extension NumberFormatter {
    static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

private extension NumberEditor {
    var decimalFromInternalText: NSDecimalNumber {
        let decimal = decimalFromInternalText(internalText)
        guard decimal != .negativeZero else { return .zero }
        return decimal
    }

    private func decimalFromInternalText(_ internalText: String) -> NSDecimalNumber {
        var textWithDecimal = String(Array(repeating: Character("0"), count: 20)) + internalText
        textWithDecimal.insert(".", at: textWithDecimal.index(textWithDecimal.endIndex, offsetBy: -minimumFractionDigits, limitedBy: textWithDecimal.startIndex)!)
        let value = NSDecimalNumber(string: textWithDecimal)
        let number = formatter.value(forFormattedValue: value)
        if number == .zero && isNegative { // To handle '-0'
            return .negativeZero
        }
        return isNegative ? number.multiplying(by: -1) : number
    }

    mutating func updateInternalText(from value: NSDecimalNumber) {
        let value = formatter.formattedValue(for: value)
        var chars = value.stringValue.map { character in character == "." ? decimalCharacter : character }

        if minFractionDigits > 0 {
            if let i = chars.firstIndex(of: decimalCharacter) {
                let distance = i.distance(to: chars.endIndex) - 1
                if distance < minFractionDigits {
                    chars += Array(repeating: "0", count: minFractionDigits - distance)
                } else {
                    chars.removeLast(distance-minFractionDigits)
                }
            } else {
                chars.append(decimalCharacter)
                chars += Array(repeating: "0", count: minFractionDigits)
            }
        }
        internalText = "0"
        alwaysShowsDecimalSeparator = false
        minimumFractionDigits = minFractionDigits
        chars.forEach { insertCharacter($0) }
        isNegative = value < .zero
    }

    mutating func append(_ character: Character) {
        if internalText == "0" {
            internalText = ""
        }
        let newText = internalText.appending(String(character))
        if isInternalTextValid(newText) {
            internalText = newText
        }
    }

    mutating func deleteLast() {
        let previous = internalText
        internalText = String(internalText.dropLast())
        if internalText.isEmpty { // `-3` -> `-0` and `-0` -> `0`
            internalText = "0"
            if previous == "0" {
                isNegative = false
            }
        }
    }

    private func isInternalTextValid(_ internalText: String) -> Bool {
        let value = decimalFromInternalText(internalText)
        if let maximum = formatter.maximum, value > NSDecimalNumber(value: maximum.doubleValue) {
            return false
        }
        if let minimum = formatter.minimum, value < NSDecimalNumber(value: minimum.doubleValue) {
            return false
        }
        return true
    }
}

private extension NumberEditor {
    var alwaysShowsDecimalSeparator: Bool {
        get { return formatter.alwaysShowsDecimalSeparator }
        set { mutatingFormatter.alwaysShowsDecimalSeparator = newValue }
    }

    var minimumFractionDigits: Int {
        get { return formatter.minimumFractionDigits }
        set { mutatingFormatter.minimumFractionDigits = newValue }
    }

    var decimalCharacter: Character {
        return formatter._decimalSeparator.first!
    }

    var negativeCharacter: Character {
        return formatter.negativePrefix.first!
    }

    var formatter: NumberFormatter {
        return formatterBox.unbox
    }

    // We need to copy of formatter before modifying it if it is no longer uniquely referenced by us
    var mutatingFormatter: NumberFormatter {
        mutating get {
            if !isKnownUniquelyReferenced(&formatterBox) {
                formatterBox = Box(formatterBox.unbox.copy)
            }
            return formatterBox.unbox
        }
    }
}

private extension NumberFormatter {
    var _decimalSeparator: String {
        switch numberStyle {
        case .currency,
             .currencyPlural,
             .currencyISOCode,
             .currencyAccounting:
            return currencyDecimalSeparator
        default:
            return decimalSeparator
        }
    }
}

private extension NumberFormatter {
    var insertionIndexFromBack: Int? {
        // Find what differs between to different values to find the insertion point.
        let decimal1 = NSDecimalNumber(mantissa: 1111111111111111111, exponent: -9, isNegative: false)
        let decimal2 = NSDecimalNumber(mantissa: 2222222222222222222, exponent: -9, isNegative: false)

        guard let string1 = string(from: decimal1), let string2 = string(from: decimal2) else { return nil }

        return zip(string1, string2).reversed().firstIndex { $0 != $1 }
    }
}

private extension NumberFormatter {
    func value(forFormattedValue value: NSDecimalNumber) -> NSDecimalNumber {
        switch numberStyle {
        case .percent:
            return value.multiplying(byPowerOf10: -2)
        default:
            return value
        }
    }

    func formattedValue(for value: NSDecimalNumber) -> NSDecimalNumber {
        switch numberStyle {
        case .percent:
            return value.multiplying(byPowerOf10: 2)
        default:
            return value
        }
    }
}

private extension NSDecimalNumber {
    static let negativeZero = NSDecimalNumber(mantissa: 1, exponent: 1000, isNegative: true)
}

final class Box<A> {
    let unbox: A
    init(_ value: A) { unbox = value }
}

extension NSCopying where Self: NSObject {
    var copy: Self {
        return copy() as! Self
    }
}

func < (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedAscending
}

func > (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedDescending
}
