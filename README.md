<img src="https://github.com/iZettle/Form/blob/master/form-logo.png?raw=true" height="140px" />

[![Build Status](https://travis-ci.org/iZettle/Form.svg?branch=master)](https://travis-ci.org/iZettle/Form)
[![Platforms](https://img.shields.io/badge/platform-%20iOS-gray.svg)](https://img.shields.io/badge/platform-%20iOS-gray.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Form is an iOS Swift library for building and styling UIs. A toolbox of highly composable utilities for solving common UI related problems, such as:

- **[Forms](Documentation/Forms.md)** - Building table like UIs with mixed row types.
- **[Tables](Documentation/Tables.md)** - Populate tables and collection views.
- **[Layout](Documentation/Layout.md)** - Laying out and updating view hierarchies.
- **[Styling](Documentation/Styling.md)** - Styling of UI components.
- **[Keyboard](Documentation/Keyboard.md)** - Adjusting for keyboards.
- **[Values](Documentation/Values.md)** - Displaying and edit custom types.

Even though Form is flexible, it is also opinionated and has a preferred way of building UIs:

- Build and layout UIs programmatically.
- Use reactive programming for event handling.
- Promote small reusable components and extensions to subclassing.
- Prefer being explicit and declarative using value types.

The Form framework builds heavily upon the [Flow framework](https://github.com/iZettle/Flow) to handle event handling and lifetime management.

## Example usage

To showcase the main ideas behind Form we will build a simple messages application based on a `Message` model:

```swift
struct Message: Hashable {
  var title: String
  var body: String
}
```

The application will consist of a view listing our messages and a view for composing new messages:

![Messages and compose views using system styling](https://github.com/iZettle/Form/blob/master/Documentation/MessagesSystem.png?raw=true)

Form makes it easy to build form like interfaces that are styled and laid out as table views that are so common in iOS applications:

```swift
extension UIViewController {
  func presentComposeMessage() -> Future<Message> {
    self.displayableTitle = "Compose Message"

    let form = FormView()
    let section = form.appendSection()

    let title = section.appendRow(title: "Title").append(UITextField(placeholder: "title"))
    let body = section.appendRow(title: "Body").append(UITextField(placeholder: "body"))

    let isValid = combineLatest(title, body).map {
      !$0.isEmpty && !$1.isEmpty
    }

    let save = navigationItem.addItem(UIBarButtonItem(system: .save), position: .right)
    let cancel = navigationItem.addItem(UIBarButtonItem(system: .cancel), position: .left)

    return Future { completion in
      let bag = DisposeBag()

      bag += isValid.atOnce().bindTo(save, \.enabled)

      bag += save.onValue {
        let message = Message(title: title.value, body: body.value)
        completion(.success(message))
      }

      bag += cancel.onValue { 
        completion(.failure(CancelError()))
      }

      bag += self.install(form) { scrollView in
        bag += scrollView.chainAllControlResponders(shouldLoop: true, returnKey: .next)
        title.provider.becomeFirstResponder()
      }

      return bag
    }
  }
}
```

Form extends several UI components with initializers accepting a style parameter that often has a default that can be globally overridden by your app:

![Messages and compose views using custom styling](https://github.com/iZettle/Form/blob/master/Documentation/MessagesCustom.png?raw=true)

Where the form shown above is built using stack views, Form also provides helpers to populate `UITableView`s for improved performance when you have larger or dynamic tables:

```swift
extension Message: Reusable {
  static func makeAndConfigure() -> (make: RowView, configure: (Message) -> Disposable) {
    let row = RowView(title: "", subtitle: "")
    return (row, { message in
      row.title = message.title
      row.subtitle = message.body
      // Returns a `Disposable` to keep activities alive while being presented.
      return NilDisposer() // No activities.
    })
  }
}

extension UIViewController {
  // Returns a `Disposable` to keep activities alive while being presented.
  func present(messages: ReadSignal<[Message]>) -> Disposable {
    displayableTitle = "Messages"
    let bag = DisposeBag()

    let tableKit = TableKit<EmptySection, Message>(bag: bag)

    bag += messages.atOnce().onValue {
      tableKit.set(Table(rows: $0))
    }

    bag += install(tableKit)

    return bag
  }
}
```

Both forms and tables are using the same styling allowing you to seamlessly intermix tables and forms to get the benefit of both.

## Requirements

- Xcode `9.3+`
- Swift 5
- iOS `9.0+`

## Installation

#### [Carthage](https://github.com/Carthage/Carthage)

```shell
github "iZettle/Form" >= 1.0
```

#### [Cocoa Pods](https://github.com/CocoaPods/CocoaPods)

```ruby
platform :ios, '9.0'
use_frameworks!

target 'Your App Target' do
  pod 'FormFramework', '~> 1.0'
end
```

## Introductions 

- **[Forms](Documentation/Forms.md)** - Building table like UIs with mixed row types.
- **[Tables](Documentation/Tables.md)** - Populate table and collection views with your model types.
- **[Layout](Documentation/Layout.md)** - Work with layouts and view hierarchies.
- **[Styling](Documentation/Styling.md)** - Create custom UI styles.
- **[Keyboard](Documentation/Keyboard.md)** - Adjust your UI for keyboards.
- **[Values](Documentation/Values.md)** - Display and edit custom types.

## Localization

Most of Form's APIs for working with end-user displayable texts accept values conforming to `DisplayableString` instead of a plain string. You can still use plain strings when using these APIs as `String` already conforms to `DisplayableString`. However, if your app is localized, we highly recommend implementing your own type for localized strings, for example like:

```swift
struct Localized: DisplayableString {
  var key: String
  var displayValue: String { return translate(key) }
}

let label = UILabel(value: Localized("InfoKey"))
```

Or if you prefer to be more concise:

```swift
prefix operator §
prefix func §(key: String) -> Localized {
  return Localized(key: key)
}

let label = UILabel(value: §"InfoKey")
```

## Presentation framework

We highly recommend that you also check out the [Presentation framework](https://github.com/iZettle/Presentation). Form and Presentation were developed closely together and share many of the same underlying design philosophies.

## Field tested

Form was developed, evolved and field-tested over the course of several years, and is pervasively used in [iZettle](https://izettle.com)'s highly acclaimed point of sales app.

## Collaborate

You can collaborate with us on our Slack workspace. Ask questions, share ideas or maybe just participate in ongoing discussions. To get an invitation, write to us at [ios-oss@izettle.com](mailto:ios-oss@izettle.com)
