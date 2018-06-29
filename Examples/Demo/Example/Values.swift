//
//  Values.swift
//  Example
//
//  Created by Måns Bernhardt on 2018-06-08.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Form

extension UIViewController {
    func presentValues() -> Disposable {
        displayableTitle = "Values"
        let bag = DisposeBag()
        let form = FormView()

        do {
            let section = form.appendSection(header: "Integer")

            let label = ValueLabel(value: 0)
            section.appendRow(title: "Label").append(label)

            let row = section.appendRow(title: "Field").append(ValueField(value: 4711))
            bag += row.atOnce().bindTo(label, \.value)
        }

        do {
            let section = form.appendSection(header: "Double")

            let label = ValueLabel(value: 0.0)
            section.appendRow(title: "Label").append(label)

            let row = section.appendRow(title: "Field").append(ValueField(value: 47.11))
            bag += row.atOnce().bindTo(label, \.value)
        }

        do {
            let section = form.appendSection(header: "Country Code")

            func formatter(_ text: String) -> String {
                return "+" + text
            }

            let label = ValueLabel(value: "", formatter: formatter)
            section.appendRow(title: "Label").append(label)

            /// Country code editor, e.g. +46
            let editor = ValueEditor(isValidCharacter: isDigit, minCharacters: 1, maxCharacters: 3, prefix: "+")

            let row = section.appendRow(title: "Field").append(ValueField(value: "46", editor: editor))
            bag += row.atOnce().bindTo(label, \.value)
        }

        do {
            let section = form.appendSection(header: "Quoted String")

            func formatter(_ text: String) -> String {
                return "\"\(text)\""
            }

            let label = ValueLabel(value: "", formatter: formatter)
            section.appendRow(title: "Label").append(label)

            let editor = ValueEditor(isValidCharacter: { _ in true}, prefix: "\"", suffix: "\"")

            let row = section.appendRow(title: "Field").append(ValueField(value: "Hello World!", editor: editor))

            bag += row.atOnce().bindTo(label, \.value)
        }

        do {
            let section = form.appendSection(header: "Card Number")

            func formatter(_ text: String) -> String {
                let text = text + String(repeating: "-", count: 16 - text.count)
                return String(text.enumerated().map { index, char -> [Character] in
                    let char = (index < 12 && char != "-") ? "*" : char
                    return index > 0 && index % 4 == 0 ? [" ", char] : [char]
                }.joined())
            }

            let label = ValueLabel(value: "", formatter: formatter)
            section.appendRow(title: "Label").append(label)

            let valueLabel = UILabel(value: "")
            section.appendRow(title: "Value").append(valueLabel)

            /// Credit card editor 4 by 4 digits
            let editor = ValueEditor(isValidCharacter: isDigit, maxCharacters: 16) {
                let text = formatter($0)
                return (text, text.index(text.startIndex, offsetBy: $0.count+min(3, ($0.count)/4)))
            }

            let row = section.appendRow(title: "Field").append(ValueField(value: "", editor: editor))
            bag += row.atOnce().bindTo(label, \.value)
            bag += row.atOnce().map { $0 }.bindTo(valueLabel, \.value)
        }

        do {
            let section = form.appendSection(header: "Currency Formatter")

            let formatter = NumberFormatter()
            formatter.currencyCode = "USD"
            formatter.numberStyle = .currency

            let label = ValueLabel(value: 0.0, formatter: formatter)
            section.appendRow(title: "Label").append(label)

            let row = section.appendRow(title: "Field").append(ValueField(value: 47.11, formatter: formatter))
            bag += row.atOnce().bindTo(label, \.value)
        }

        do {
            let section = form.appendSection(header: "Custom Euro Type")

            let label = ValueLabel(value: Euro(0))
            section.appendRow(title: "Label").append(label)

            let row = section.appendRow(title: "Field").append(ValueField(value: Euro(47.11)))
            bag += row.atOnce().bindTo(label, \.value)
        }

        bag += self.install(form) { scrollView in
            scrollView.firstPossibleResponder?.becomeFirstResponder()
            bag += scrollView.chainAllControlResponders(shouldLoop: true, returnKey: .next)
        }

        return bag
    }
}

struct Euro {
    var amount: Double
    init(_ amount: Double) {
        self.amount = amount
    }
}

extension ValueLabel where Value == Euro {
    convenience init(value: Value, style: TextStyle = .default) {
        self.init(value: value, keyPath: \.amount, formatter: euroFormatter)
    }
}

extension ValueField where Value == Euro {
    convenience init(value: Value, style: FieldStyle = .decimal) {
        let editor = NumberEditor<Double>(formatter: euroFormatter)
        self.init(value: value, keyPath: \.amount, editor: editor, style: style)
    }
}

private let euroFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.currencyCode = "EUR"
    formatter.numberStyle = .currency
    return formatter
}()
