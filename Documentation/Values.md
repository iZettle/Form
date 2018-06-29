# Values - Displaying and edit custom types

For more convenient and type-safe displaying and editing of your custom types,  Forms provides the `ValueLabel` and `ValueField` types.

## ValueLabel

`ValueLabel` is like a `UILabel` but generic on a custom type. It exposes a value property and uses a formatter to convert a value to a `String` for display:

```swift
let label = ValueLabel(value: 4711, formatter: { "\($0) kg" })
label.value = 75
```

You can also provide an instance of a `Formatter`:

```swift
let euroFormatter = NumberFormatter()
euroFormatter.currencyCode = "EUR"
euroFormatter.numberStyle = .currency

let label = ValueLabel(value: 47.11, formatter: euroFormatter)
```

If you often use the same formatter for your custom type you can add a convenience initializer:

```swift
struct Euro {
  var amount: Double
}

extension ValueLabel where Value == Euro {
  convenience init(value: Value, style: TextStyle = .defaultLabel) {
    self.init(value: value, keyPath: \.amount, formatter: euroFormatter)
  }
}
```

This means you do not have to provide explicit formatter everywhere:

```swift
let label = ValueLabel(value: Euro(4711))
label.value = Euro(0)
```

Form already comes with similar initializers for integer and floating point types:

```swift
let label = ValueLabel(value: 47.11)
label.value += 100
```

## ValueField

Similar to `ValueLabel`, `ValueField` is like a `UITextField` but generic on a custom type for editing custom values. However, to be able to edit a value it needs an instance of a `TextEditor`. `TextEditor` is a protocol and Form comes with two concrete implementations named `ValueEditor` and `DecimalEditor`.

`ValueEditor` comes with several convenience initializers:

```swift
/// Country code editor, e.g. +46
let editor = ValueEditor(isValidCharacter: isDigit, 
                         minCharacters: 1, 
                         maxCharacters: 3, 
                         prefix: "+")

let field = ValueField(value: "46", editor: editor)
```

When working with numeric values it is often better to use `NumberEditor` that uses a `NumberFormatter` to derive its behavior and formatting:

```swift
let editor = NumberEditor<Double>(formatter: euroFormatter)
let field = ValueField(value: 47.11, editor: editor)
```

For integer and floating point values you can pass the formatter directly:

```swift
let field = ValueField(value: 47.11, formatter: euroFormatter)
```

To avoid repetition, you typically add convenience initializers to `ValueField` for your custom types:

```swift
extension ValueField where Value == Euro {
  convenience init(value: Value, style: FieldStyle = .decimal) {
    let editor = NumberEditor<Double>(formatter: euroFormatter)
    self.init(value: value, keyPath: \.amount, editor: editor, style: style)
  }
}
```
 
This allows you to use your custom types directly with `ValueField`s:

```swift
let field = ValueField(value: Euro(0))
```
