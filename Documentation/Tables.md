# Tables - Populate tables and collection views

Whereas [forms](./Forms.md) can be used for building tables with uniform row types, such as:

```swift
let items: [Item] // large collection
for item in items {
  section.appendRow(title: item.name)
}
```

Forms were primarily designed for building smaller tables with rows of mixed row type. For tables with uniform rows that either might contain many rows or where the rows might dynamically change, Form provides utilities for rendering these tables using `UITableView`s or `UICollectionView`s.

## Table

For populating table or collection views, Form provides its own collection type `Table` for organizing data into sections and rows. The most basic table is one with no sections, or rather one section of type `EmptySection` (type alias for `Void`):

```swift
let table = Table(rows: items) // -> Table<EmptySection, Item>
```

If your data should be presented in different sections you can build your table either from constructing an array of sections and rows:

```swift
let table = Table<String, Int>(sections: [("1", [0, 1, 2]), ("2", [3, 4])])
```

Or by passing a `sectionValue` function to provide the sections:

```swift
let table = Table<String, Int>(rows: 0..<100) { row in 
  row%5 == 0 ? "\(row/5)" : nil
}
```

## Reusable

To be able to present a `Table`, its rows and sections need to be converted into views. This is typically handled by conforming your model to the `Reusable` protocol:

```swift
struct Item {
  let name: String 
}

extension Item: Reusable {
  static func makeAndConfigure() -> (make: RowView, configure: (Item) -> Disposable) {
    let row = RowView(title: "")
    return (row, { item in
      row.title = item.name
      return NilDisposer()
    })
  }
}
```

When conforming to `Reusable` you provide a way to make new views that can be reused and will be configured every time they are reused using a configure function. For rows it is useful to return an instances of `RowView` (see [forms](./forms)).

## Reusable of mixed types

As `Either` conditionally conform to `Resusale` if both `Left` and `Right` do, you can use `Either` to handle tables with mixed types:

```swift
typealias Row = Either<Int, String>
let table = Table<(), Row>(rows: [.left(1), .right("A")])
```

If you have more than two different types you can further nest `Either` types:

```swift
typealias Row = Either<Either<Int, String>, Double>
let table = Table<(), Row>(rows: [.left(.left(1)), .left(.right("A")), .right(3.14)]])
```

If you are ok with losing type information you can also consider using the `MixedReusable` helper:

```swift 
var mixedTable = Table<(), MixedReusable>(rows: [.init(1), .init("A"), .init("B"), .init(2)])
```

## HeaderFooterReusable

If you conform your `Table`'s `Section` type to `Reusable` a table's section will be rendered by the view provided by `makeAndConfigure()`. However if you like to provide both a header and a footer view from your section model data, you can conform your `Section` type to `HeaderFooterReusable` and provide separate header and footer types for rendering:

```swift
struct MySection { ... } 

extension MySection: HeaderFooterReusable {
  var header: MyHeaderType { ... }
  var footer: MyFooterType { ... }
}
```

As it is common with header and footer that are just strings, Form includes the `HeaderFooter` type for your convenience:

```swift
struct HeaderFooter: HeaderFooterReusable, Hashable {
  var header: String   
  var footer: String
}
```

## TableKit

Once you have your data in a `Table` and your `Row` and `Section` types conforming to `Reusable`, you can construct a `TableKit` that will provide a `UITableView` set up with a proper data source and delegate:

```swift
let items: [Item]
let table = Table(rows: items)

let tableKit = TableKit(table: table, bag: bag)
let tableView = tableKit.view
```

As it is common that your view controller's view will be this table view and that you would likely want to set it up for keyboard avoidance similar to when installing forms, Form provides overloads for installing table view and table kits (see [layout](./Layout.md)):

```
bag += viewController.install(tableKit)
```

If you need to update your table, you can set a new table using `TableKit`'s `table` property:

```swift
let tableKit.table = updatedTable
```

This will not, however, animate the update as `TableKit` does not know how to construct the animation instructions required by `UITableView`. For `TableKit` to be able to do that it needs something to identify one row or section from another. 

```swift
struct Item {
    let identifier: UUID
    let name: String 
}

tableKit.set(updatedTable, rowIdentifier: { $0.identifier })
```

However, you do not always have to provide explicit identifiers, as `TableKit` provides several overloads of `set` for handling models that are e.g. `Hashable` or reference types (`AnyObject`).
 
To drive the table view, table kit is using instances of `TableViewDelegate` and `TabelViewDataSource`. Those two types expose several signals and delegate helpers to make it easier to work with table views such as handle the selection of rows:

```swift
bag += delegate.didSelectRow.onValue { row in ... }
```
 
## Mixing forms and tables

Sometimes you want the convenience of using forms of mixed row content and the performance or dynamism of using `TableKit` for your uniform row content. It might, for example, be only part of the table that can and needs to be able to grow large, and where performance matters. 

For these cases, Form provides some helpers to set up your table view to have forms as its header or footer, and also support for the table and form to seamlessly blend. This is in part possible as both forms and table kit shares the same styles.

If your content is in separate sections you can just setup you table kit's footer or header with a form and make sure to remove any form insets between the table and form:

```swift
let form = FormView(style: FormStyle.default.openedBottom)
/// Build form...
tableKit.headerView = form
```

On the other hand, if you need the form and table to be blended together as if being one section you need to open up the adjacent bottom and top:

```swift
let style: DynamicTableViewFormStyle
let tableKit = TableKit(table: table, style: style.openedTop, bag: bag)

let form = FormView(style: style.form.openedBottom)
let section = form.appendSection(style: style.section.openedBottom)
tableKit.headerView = form
```

## Collection views

Form also provides a corresponding `CollectionKit` type for working with collection views. It is very similar to `TableKit` and also uses a `Table` to populate its views.
