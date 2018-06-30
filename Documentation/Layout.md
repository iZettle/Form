# Layout - Laying out and updating view hierarchies

The layout of a typical iOS application's UI consists of organizing views into hierarchies and letting auto layout position them by setting up constraints between views. Even though UIKit has great support for handling most of our layout needs, there is always room for some handy extensions and helpers to make working with layouts and view hierarchies even nicer.

## Scroll views

Few layouts can rely on a static layout that will always fit within a screen. Often we have to work with devices of many different screen sizes. This means that we can seldom guarantee that all content will fit and hence we often place our content in scroll views.

Form adds several helpers to make it easier to work with scroll views. For example, to embed a view in a scroll view and to set up the required constraints:

```swift
scrollView.embedView(view, scrollAxis: .vertical)
```

If you want to embed multiple views where spacing is added between views to evenly fill up to the scroll views height, you can use:

```swift
bag += scrollView.embedWithSpacingBetween(views)
```

Form also provides helpers to pin a view to an edge of a scroll view and update the insets accordingly:

```swift
bag += scrollView.embedPinned(button, edge: .bottom, minHeight: 44)
```

## View controller installation 

As it is so common to set up your views in scroll views and also to set up your view controller to use this scroll view, Form provides the install helper: 

```swift
bag += viewController.install(view)
```

This will create a scroll view and embed the view setup with constraints for vertical scrolling. Furthermore, it will by default setup the scroll view to adjust its insets to make room for a keyboard as well as scroll any first responder into view if it got covered by the keyboard. You can customize the behavior of `install()` by passing an explicit options parameter (`InstallOptions`). 

You can also provide a configure closure for further setup once the created scroll view has been added to a window:

```swift
bag += viewController.install(view) { scrollView in
  // Not called until the scroll view has been added to a window.
}
```

Install can also be used for adding multiple views to a scroll view, and by default, space is added between views to evenly fill up to the scroll views height:

```swift
bag += viewController.install(topView, bottomView)
``` 

## View embedding

Embedding views and setting up proper constraints for common scenarios can be repetitive and hence Form comes with some nice helpers to handle the most common cases. You can optionally provide customization such as edge insets or which edges to pin to:

```swift
parent.embedView(child, edgeInsets: ..., pinToEdge:..)
```

And for convenience you can use initializers as well:

```swift
let parent = UIView(embeddedView: child, edgeInsets: ..., pinToEdge:.. )
```

## View hierarchies

Form comes with several helpers to work with view hierarchies such as getting a view's all ascendents or descendants and variants thereof. These are implemented as extensions on the `ParentChildRelational` protocol that `UIView`, as well as `UIViewController` and `CALayer`, conform to.

```swift
let controls = view.allDescendants(ofType: UIControl.self)
```

## Working with constraints

Even though the many helpers provided by UIKit and Form will set up the constraints for you, you sometimes need to set some up by hand. Form comes with some convenience helpers to make it even more readable to work with layout anchors:

```swift
let topConstraint = self.topAnchor == view.topAnchor - margin 
activate(
  topConstraint,
  self.centerXAnchor == view.centerXAnchor,
  self.widthAnchor == view.widthAnchor*2,
  self.bottomAnchor == view.bottomAnchor + margin)
```

You can use ==, <= and >= to construct constraints between anchors and adjusting the constant with + and - and the multiplier with * and /. You can also use `activate()` for activating the constraints and `deactivate()` to deactivate them. 

## UINavigationItem

Navigation bars can hold several items to either the left or the right of a navigation bar. Form comes with some helpers to add items that also returns the added items for convenience:

```swift
let item = navigationItem.addItem(.init(system: .done), position: .right)
bag += item.onValue { ... }
``` 

## SubviewOrderable

`SubviewOrderable` is a simple protocol for working with views such as `UIStackView` that has an array of ordered views. In Form, views such as `SectionView` and the helper `RowAndProvider` also conforms to this protocol. This allows us to add convenience helpers to `SubviewOrderable` such as different kinds of append and prepend helpers that will be available to all these conforming types. These are especially useful for building `RowView`s:

```swift
let row = RowView(title: "title", subtitle: "subtitle")
  .prepend(iconImage)
  .append("details")
  .append(.chevron)
```
