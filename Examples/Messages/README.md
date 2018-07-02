## Messages Example

This app shows how Form works nicely with the [Presentation framework](https://github.com/iZettle/Presentation).

It combines the versions of the `Messages` functionality implemented in this [Presentation example](https://github.com/iZettle/Presentation/tree/master/Examples/Messages) (where we focused on the presentation of view controllers and the data going in and out) and from [Form's demo app](https://github.com/iZettle/Form/blob/master/Examples/Demo/Example/Messages.swift) (where we focus on what goes into a view controllers view).

### Presentation utilities
Even though From and Presentation can be used independently, they were evolved and designed to work together. That's why Form comes with several helpers for integrating with Presentation placed behind a `canImport` compiler test.

To use them, you need the `Presentation` dependency to be resolved before `Form` is built. The way we did it in the example project is by using the CocoaPods [subspec](https://guides.cocoapods.org/syntax/podspec.html#subspec) exposed by Form:
```
pod FormFramework/Presentation
```
