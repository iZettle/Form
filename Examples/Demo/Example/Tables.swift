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
