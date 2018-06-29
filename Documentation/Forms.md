# Forms - Building table like UIs with mixed row types

It is quite common with UIs laid out and styled as table views. But these tables are sometimes using rows with mixed types. A good example is iOS's general settings. Building tables with mixed row types are often hard to get right, especially if the rows being displayed might differ based on some configuration. If you ever attempted to maintain similar UIs, especially when backed by a `UITableView`, you are probably aware of the difficulties involved.

To mitigate this, Form provides three helper views; `FormView`, `SectionView` and `RowView` for building table like UIs. These views are backed by `UIStackView`s, and laid out and styled to look like `UITableView`s. They were designed for convenience and are best suited for smaller tables. For more performant tables, Form provides [`TableKit`](./Tables.md) for working with `UITableView`s and reusable rows. 

Building forms using `FormView`, `SectionView` and `RowView` is straightforward: 

```swift
let form = FormView()
let section = form.appendSection(header: "About")
let row = section.appendRow(title: "Credits")
bag += row.onValue { /* show credits */ } 
```

Here we can see that we can build our UI more declaratively and directly. This is in sharp contrast to using table views where you have an indirection using indices, data sources and cells.

As you build you table using code it is also simple to make them dynamic based on some configuration parameters:

```swift
if hasFeature {
  let section = form.appendSection(header: "Feature") 
  if hasSubFeature {
    let row = section.appendRow(title: "Sub feature")
  }
}
```

To build this using table view's indirection would require a delicate juggling of section and row indices.

## FormView

At the root of a form is the `FormView` that holds vertically laid out section views:

```swift
let form = FormView()
let section = SectionView(header: ..., footer: ...)
form.append(section)
```

As adding sections to a form is so common there are convenience helpers to write this more succinctly:

```swift
let section = form.appendSection(header: ..., footer: ...)
```

But it is worth pointing out that you can append any view to a form, not only section views, making it easier to build custom UI:

```swift
form.append(customView)
```

## SectionView

A `SectionView` holds an array of vertically laid out row views, optionally starting with header and ending with a footer.

Similar to `FormView` you can add any view to a section:

```swift
let section = form.appendSection()
section.append(customView)
```

But more commonly, you add row views instead:

```swift
let row = RowView(title: ...)
section.append(row)
```

Or more succinctly:

```swift
let row = form.appendRow(title: ...)
```

By using `RowView`s we also ensure the layout is updated to use the provided `SectionStyle`'s `rowInsets` and `itemSpacing`:

```swift
let style = SectionStyle.default.restyle { style in
  style.rowInset.left = 40
  style.itemSpacing = 20
}

let section = form.appendSection(style: style)
```

## RowView

A `RowView` holds an array of horizontally laid out views. You typically build a row starting out with a title (and optionally subtitle) and then appends (or prepends) more views to it:

```swift
let row = RowView(title: "title", subtitle: "subtitle")
  .prepend(iconImage)
  .append("details")
  .append(.chevron)
  
section.append(row)  
```

Or more conveniently:

```swift
let row = section.appendRow(title: "title", subtitle: "subtitle")
  .prepend(iconImage)
  .append("details")
  .append(.chevron)
```

## RowAndProvider

When adding a `RowView` to a section it returns a `RowAndProvider` holding both the row view and a `Signal<()>` for observing selections of the row:

```swift
bag += section.appendRow(title: "title")  // -> RowAndProvider<Signal<()>>
  .onValue { /* row tapped */ }
```

A `RowAndProvider` behaves much like a standalone `RowView`, and you can continue appending and prepending views to its row:

```swift
let row = section.appendRow(title: "title") // - RowAndProvider
  .prepend(iconImage)  // - RowAndProvider
  .append("details")  // - RowAndProvider
  .onValue { /* row tapped */ }
```

But as seen above `RowAndProvider` also takes the role of a signal so you can in the case above call `onValue` to observe the row being tapped.

`RowAndProvider` is generic on a `Provider` type conforming to `SignalProvider`.  As for the example above, the provider was just a basic signal `Signal<()>` for observing row taps. But if you append a view that conforms to `SignalProvider`, such as many `UIControl`s, `append` will return an updated `RowAndProvider` holding the added view as its provider:

```swift
let enabledSwitch = UISwitch(...)
let row = RowView(title: "title") // -> RowView
  .append(enabledSwitch) // -> RowAndProvider<UISwitch>
```

Now `RowAndProvider` holds the switch and provides the switch's signal for convenience:

```swift
bag += row.onValue { enabled in /* switch updated */ }
```

If you add another providing view to a `RowAndProvider` it will change to provide the latest view.

```swift
bag += section.appendRow(title: "title") // -> RowAndProvider<Signal<()>>
  .append(enabledSwitch) // -> RowAndProvider<UISwitch>
  .onValue { enabled in ... }
```

If you want to opt out of changing the provider you can cast the appended provider to a `UIView`:

```swift
bag += section.appendRow(title: "title") // -> RowAndProvider<Signal()>
  .append(enabledSwitch as UIView) // -> RowAndProvider<Signal()>
  .onValue { /* row tapped */ }

bag += enabledSwitch.onValue { enabled in ... }
```

By using the power of Flow's signals together with forms we can build our UI and logic in a more declarative way:

```swift
let feature: ReadWriteSignal<Bool>
bag += section.appendRow(title: "Feature")
  .append(UISwitch()) // -> The providedSignal is ReadWriteSignal<Bool>
  .bidirectionallyBindTo(feature.atOnce())
```
