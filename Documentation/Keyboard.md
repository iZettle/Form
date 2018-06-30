# Keyboard - Adjusting for keyboards

Working with keyboards on iOS can be a challenge as they are virtual and take up a considerable amount of the screen once presented. As we do not want the keyboard to cover important UI our layout has to react to keyboard changes.

## Scroll views 

Scroll views are great for handling dynamic content as well as different screen sizes. Scroll views are also really useful for handling keyboards as their insets can be adjusted. This is something Form takes advantage of:

```swift
bag += scrollView.adjustInsetsForKeyboard()
```

Form can also make sure the current first responder view is kept visible:

```swift
bag += scrollView.scrollToRevealFirstResponder()
```

For convenience Form's `UIViewController.install()` helper will set these up when using the default options:

```swift
// Will install the view in a scroll view and setup keyboard avoidance.
bag += viewController.install(view)
```

## Keyboard events

Sometimes you need to make other adjustments based on keyboard events. It is important that these adjustments are performed in order. Form solves this by delivering keyboard events to parents before their children. That is why `keyboardSignal()` is called on an instance of a view:

```swift
bag += view.keyboardSignal().onValue { keyboardEvent in 
  keyboardEvent.animation.animate {
      // Animate updates to match the keyboard animation.
  }
}
```

If you need to affect the order of events delivered to a specific view, you can optionally provide a priority (`KeyboardEventPriority`). This is useful for views such as scroll views that do several independent adjustments.

## View port events

To simplify keyboard adjustments it is sometimes useful to know what area of the screen that is not covered by the keyboard so you can update the frame of some UI to fit within that visible area. For this Form provides the `viewPortSignal`.

```swift
bag += view.viewPortSignal().onValue { viewPort in 
  self.frame = /// use viewPort to calculate.
}
```

As well as the `viewPortEventSignal` when you need access to the animation parameters:

```swift
bag += viewPortEventSignal().onValue { event in 
  event.animation.animate {
    self.frame = /// use event.viewPort to calculate.
  }
}
```

## Working with responders

Form also comes with several helpers to make it easier to work with responders. By using `setNextResponder()` you could set up a control to set a new first responder once it ends editing on exit:

```swift
let emailField = UITextField(...)
let passwordField = UITextField(...)
bag += emailField.setNextResponder(passwordField)
```

Or more conveniently you can chain several controls together:

```swift
bag += chainResponders(emailField, passwordField)
```

And update the `returnKey` of these controls:

```swift
bag += chainResponders(emailField, passwordField, returnKey: .next)
```

As well as specifying whether the last controller should loop back to the first one:

```swift
bag += chainResponders(emailField, passwordField, shouldLoop: true)
```

There is also a powerful helper that finds all descendant controls of a view and chains them together ordered top-left to bottom-right:

```swift
bag += rootView.chainAllControlResponders(returnKey: .next)
```
