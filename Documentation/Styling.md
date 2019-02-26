# Styling - Styling of UI components

Modern iOS applications often come with custom styling of their UI components. UIKit provides several different approaches for styling your UI. Either you set them explicitly through properties on your views, or you work indirectly with these properties using interface builder or the appearance manager. Form adds programmatic support for styling your UI using style types that allow for easier reuse and modification of your styles.

## Styles

Form supports several different kinds of styles, where some are used mainly to compose other styles. You typically pass a style when you construct your UI components:

```swift
let label = UILabel(value: "Hello", style: .header)
```

Many UI components come with default styles, so you can skip passing styles explicitly:

```swift
let label = UILabel(value: "Hello")
```

A UI component's style is often available from a mutable `style` property as well, allowing convenient updating of styling: 

```swift
label.style = .footer
label.style.color = .red
```

By using the `restyled` helper, new styles can easily be created based on existing styles:

```swift
let footStyle = TextStyle.header.restyled { style in
  style.font = ...
  style.color = ...
}
```

For commonly reused styles we recommend adding them as static extensions:

```swift
extension TextStyle {
    static let header = defaultLabel.restyled { ... }
}
```

And for common restyling, you can add helpers such as:

```swift
extension TextStyle {
  func colored(_ color: UIColor) -> TextStyle {
    return restyled { $0.color = color }
  }
}
```

Form comes with many similar helpers such as the one above allowing for a more declarative restyling:

```swift
let footer = TextStyle.header.colored(.blue).resized(to: 24)
```

## Dynamic styles

Some styles might change based on changes in the application environment such as traits changes. For these styles, there is a corresponding `DynamicStyle` that produces styles based on some dynamic properties such as `UITraitCollection`. This is true for `FormStyle` and `SectionStyle` used for styling table like views such as `UITableView`, `FormView` and `SectionView`.

Dynamic styles can also be restyled:

```swift
let customSection = DynamicSectionStyle.default.restyled { style in
  style.header.text.color = .red
}
```

And if you need to adjust differently based on the traits:

```swift
let dynamicSection = customSection.restyledWithStyleAndInput { style, traits in
  let isCompact = traits.horizontalSizeClass = .compact
  style.header.text.resized(to: isCompact ? 14 : 18)
}
```

## Default styling

Many styles and UI components have a default style that will be used when an explicit style is not passed to an initializer. By default, these defaults try to match iOS's system styling. However new defaults can be set up via the `DefaultStyling` style:

```swift
extension DefaultStyling {
  static let custom = DefaultStyling(...)
}
```

And the default styling can be updated by reassigning `defaults`:

```swift
DefaultStyling.defaults = .custom
```

You should preferably set up the defaults early on in your applications life cycle. 

If you want to support some kind of application theming by updating the defaults while the UI is presented, you have to reload the views (or update their styles explicitly). It is also important to set up your custom styles as computed properties instead of stored, so they will re-evaluate with the currently selected defaults instead of being cached.  

## Backgrounds

Several UI components such as buttons and sections use images to style their backgrounds. If you want to create these images procedurally, Form provides some helper styles such as `BackgroundStyle` and `SectionBackgroundStyle`. 

```swift
let background = BackgroundStyle(border: BorderStyle(...), color: ...) 
let image = UIImage(image: background)
```

## TextStyle

`TextStyle` supports the same styling as attributed strings. Not all attributes are exposed as convenience properties though. You can still set these using:

```swift
textStyle.setAttribute(letterSpacing, for: .kern)
```

But preferably you should add helpers instead:

```swift
extension TextStyle {
  var letterSpacing: Float {
    get { return attribute(for: .kern) ?? 0 }
    set { setAttribute(newValue, for: .kern, defaultValue: 0) }
  } 
}
```

Text styles also support registering your own custom string transformations via the `TextStyle.registerCustomTransform()`. For example, Form provides the `textCase` transformation and comes with helpers such as uppercased:

```swift
let header = TextStyle.default.uppercased
```
