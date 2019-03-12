//
//  Tables.swift
//  Example
//
//  Created by Måns Bernhardt on 2018-05-17.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Form

extension UIViewController {
    func presentTableUsingForm(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "Forms"

        let form = FormView(style: style.form)

        for tableSection in table.sections {
            let section = form.appendSection(header: tableSection.value, style: style.section)
            for item in tableSection {
                section.appendRow(title: "Index \(item)", subtitle: "Subtitle \(item)")
            }
        }

        return self.install(form)
    }

    func presentTableUsingKit(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit"
        let bag = DisposeBag()

        let tableKit = TableKit(table: table, style: style, bag: bag, headerForSection: { table, item in
            table.dequeueHeaderFooterView(forItem: item) { reuseIdentifier in
                let label = UILabel()
                let header = UITableViewHeaderFooterView(view: label, style: style.header, formStyle: style.form, reuseIdentifier: reuseIdentifier)
                return (header, { item in
                    label.value = item
                    return NilDisposer()
                })
            }
        }, cellForRow: { table, item in
            table.dequeueCell(forItem: item) { reuseIdentifier in
                let row = RowView(title: "", subtitle: "")
                return (UITableViewCell(row: row, reuseIdentifier: reuseIdentifier, style: style), { item in
                    row.title = "Index \(item)"
                    row.subtitle = "Subtitle \(item)"
                    return NilDisposer()
                })
            }
        })

        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&table, &swapTable)
            tableKit.set(table)
        }

        return bag
    }

    func presentTableUsingKitAndReusable(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit and Reusable"
        let bag = DisposeBag()

        let tableKit = TableKit(table: table, style: style, bag: bag)
        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&table, &swapTable)
            tableKit.set(table)
        }

        return bag
    }

    func presentTableUsingKitAndReusableWithFormHeader(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit with Form Header"
        let bag = DisposeBag()

        let tableKit = TableKit(table: table, style: style, bag: bag)

        let form = FormView(style: style.form.openedBottom)
        let section = form.appendSection(header: "Forms Section", style: style.section)
        for row in 1...3 {
            section.appendRow(title: "Form row", subtitle: "Subtitle \(row)")
        }
        tableKit.headerView = form

        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&table, &swapTable)
            tableKit.set(table)
        }

        return bag
    }

    func presentTableUsingKitAndReusableWithBlendingFormHeader(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit Blending with Form Header"
        let bag = DisposeBag()

        var table = Table(rows: 0..<7)
        var swapTable = Table(rows: 4..<12)

        let tableKit = TableKit(table: table, style: style.openedTop, bag: bag)

        let form = FormView(style: style.form.openedBottom)
        let section = form.appendSection(header: "Forms Section", style: style.section.openedBottom)
        for row in 1...3 {
            section.appendRow(title: "Form row", subtitle: "Subtitle \(row)")
        }
        tableKit.headerView = form

        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&table, &swapTable)
            tableKit.set(table)
        }

        return bag
    }

    func presentTableUsingKitAndEitherReusable(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit and Either Reusable"
        let bag = DisposeBag()

        var table = Table<String, Either<Int, String>>(sections: [
            ("Header 1", [.left(1), .right("A"), .right("B"), .left(2)]),
            ("Header 2", [.left(3), .right("C"), .left(4), .right("D")])])

        var swapTable = Table<String, Either<Int, String>>(sections: [
            ("Header 1", [.left(5), .right("C"), .right("B"), .left(2)]),
            ("Header 1b", [.left(1), .right("D"), .right("F"), .left(6)]),
            ("Header 2", [.left(3), .right("A"), .left(4), .right("E")])])

        let tableKit = TableKit(table: table, style: style, bag: bag)
        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&table, &swapTable)
            tableKit.set(table)
        }

        return bag
    }

    func presentTableUsingKitAndMixedReusable(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit and Mixed Reusable"
        let bag = DisposeBag()

        var table = Table<String, MixedReusable>(sections: [
            ("Header 1", [.init(1), .init("A"), .init("B"), .init(2.2)]),
            ("Header 2", [.init(3.14), .init("C"), .init(4), .init("D")])])

        var swapTable = Table<String, MixedReusable>(sections: [
            ("Header 1", [.init(5), .init("C"), .init("B"), .init(2.2)]),
            ("Header 1b", [.init(1), .init("D"), .init("F"), .init(6.66)]),
            ("Header 2", [.init(3.14), .init("A"), .init(4), .init("E")])])

        let tableKit = TableKit(table: table, style: style, bag: bag)
        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&table, &swapTable)
            tableKit.set(table)
        }

        return bag
    }

    func presentTableUsingKitAndNestedEitherReusable(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit and Nested Either Reusable"
        let bag = DisposeBag()
        typealias Row = Either<Either<Int, String>, Double>

        var table = Table<(), Row>(rows:
            [.left(.left(1)), .left(.right("A")), .right(3.14)]
        )

        var swapTable = Table<(), Row>(rows:
            [.left(.right("A")), .right(3.14), .left(.left(1)), .right(47.11) ]
        )

        let tableKit = TableKit(table: table, style: style, bag: bag)
        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&table, &swapTable)
            tableKit.set(table)
        }

        return bag
    }

    func presentTableUsingKitAndHeaderFooterReusable(style: DynamicTableViewFormStyle) -> Disposable {
        displayableTitle = "TableKit and HeaderFooterReusable"
        let bag = DisposeBag()

        let tableKit = TableKit(table: sectionTable, style: style, bag: bag)
        bag += self.install(tableKit.view)

        bag += self.navigationItem.addItem(UIBarButtonItem(title: "Swap"), position: .right).onValue {
            swap(&sectionTable, &swapSectionTable)
            tableKit.set(sectionTable)
        }

        return bag
    }
}

private var table = Table(sections: [("Header 1", 0..<5), ("Header 2", 5..<10)])
private var swapTable = Table(sections: [("Header 1", 0..<2), ("Header 1b", 3..<7), ("Header 2", 7..<10)])

extension Int: Reusable {
    public static func makeAndConfigure() -> (make: RowView, configure: (Int) -> Disposable) {
        let row = RowView(title: "", subtitle: "")
        return (row, { item in
            row.title = "Index \(item)"
            row.subtitle = "Subtitle \(item)"
            return NilDisposer()
        })
    }
}

extension Double: Reusable {
    public static func makeAndConfigure() -> (make: UIView, configure: (Double) -> Disposable) {
        let label = ValueLabel(value: 0.0)
        return (label, { value in
            label.value = value
            return NilDisposer()
        })
    }
}

private var sectionTable = Table(sections: [(HeaderFooter(header: "Header 1", footer: "Footer 1"), 0..<5), (HeaderFooter(header: "Header 2", footer: "Footer 2"), 5..<10)])
private var swapSectionTable = Table(sections: [(HeaderFooter(header: "Header 1", footer: "Footer 1"), 0..<2), (HeaderFooter(header: "Header 1b", footer: "Footer 1b"), 3..<7), (HeaderFooter(header: "Header 2", footer: "Footer 2"), 7..<10)])
