//
//  ValueLabel.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-01-04.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

/// A label being generic on `Value` with a custom formatter to produce a `DisplayableString`.
///
///     extension MyValue: ValueFormattable { ... }
///     let label = ValueLabel(value: myValue)
///     label.value = MyValue(..)
public class ValueLabel<Value>: UIView {
    public let label: UILabel
    public var formatter: ValueFormatter<Value> {
        didSet { updateText() }
    }

    public var value: Value {
        didSet { updateText() }
    }

    public var style: TextStyle {
        get { return label.style }
        set { label.style = newValue }
    }

    public init(value: Value, style: TextStyle = .default, formatter: @escaping ValueFormatter<Value>) {
        label = UILabel()
        self.formatter = formatter
        self.value = value
        label.style = style
        super.init(frame: .zero)
        self.embedView(label)
        updateText()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public typealias ValueFormatter<Value> = (Value) -> String

public extension ValueLabel {
    convenience init<SubValue>(value: Value, keyPath: KeyPath<Value, SubValue>, style: TextStyle = .default, formatter: @escaping ValueFormatter<SubValue>) {
        self.init(value: value, style: style) { value in
            return formatter(value[keyPath: keyPath])
        }
    }
}

public extension ValueLabel {
    convenience init(value: Value, style: TextStyle = .default, formatter: Formatter) {
        self.init(value: value, style: style, formatter: formatter.valueFormatter())
    }
}

public extension ValueLabel {
    convenience init<SubValue>(value: Value, keyPath: KeyPath<Value, SubValue>, style: TextStyle = .default, formatter: Formatter) {
        self.init(value: value, keyPath: keyPath, style: style, formatter: formatter.valueFormatter())
    }
}

public extension ValueLabel where Value: BinaryInteger {
    convenience init(value: Value, style: TextStyle = .default) {
        self.init(value: value, style: style, formatter: NumberFormatter.defaultInteger)
    }
}

public extension ValueLabel where Value: BinaryFloatingPoint & CustomStringConvertible {
    convenience init(value: Value, style: TextStyle = .default) {
        self.init(value: value, style: style, formatter: NumberFormatter.defaultDecimal)
    }
}

public extension Formatter {
    func valueFormatter<Value>() -> ValueFormatter<Value> {
        return { self.string(for: $0) ?? "" }
    }
}

private extension ValueLabel {
    func updateText() {
        label.styledText = StyledText(text: formatter(value), style: style)
    }
}
