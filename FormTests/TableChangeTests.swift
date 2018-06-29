//
//  TableDiffTests.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-10-11.
//  Copyright © 2016 iZettle. All rights reserved.
//

import XCTest
import Form
import Flow

// swiftlint:disable identifier_name
class TableChangeTests: XCTestCase {

    func test<R: Hashable, S: Hashable>(from: Table<R, S>, to: Table<R, S>) {
        let bag = DisposeBag()
        let tableView = TableKit(table: from, bag: bag) { _, _ in UITableViewCell() }
        UIWindow().addSubview(tableView.view)
        tableView.view.reloadData()
        tableView.set(to, sectionIdentifier: { $0 }, rowIdentifier: { $0 }, rowNeedsUpdate: { _, _ in true })
    }

    func test<R: Hashable, S: Hashable, T: Sequence, I: Sequence>(from: T, to: T) where T.Iterator.Element == (S, I), I.Iterator.Element == R {
        let fromTable = Table<S, R>(sections: from)
        let toTable = Table<S, R>(sections: to)
        print(fromTable, " -> ", to)
        test(from: fromTable, to: toTable)
        print(to, " -> ", fromTable)
        test(from: toTable, to: fromTable)
    }

    func testRowInsertAndRemove() {
        test(from: [("A", [])], to: [("A", [1])])
        test(from: [("A", [1])], to: [("A", [1, 2])])
        test(from: [("A", [1])], to: [("A", [1, 2, 3, 4])])
        test(from: [("A", [4])], to: [("A", [1, 2, 3, 4])])
        test(from: [("A", [4])], to: [("A", [3, 4, 5])])
    }

    func testRowMove() {
        test(from: [("A", [1, 2])], to: [("A", [2, 1])])
        test(from: [("A", [1, 2, 3])], to: [("A", [2, 1, 3])])
        test(from: [("A", [1, 2, 3])], to: [("A", [1, 3, 2])])
        test(from: [("A", [1, 2, 3])], to: [("A", [3, 2, 1])])
    }

    func testRowMixed() {
        test(from: [("A", [1, 2])], to: [("A", [2, 1, 3])])
        test(from: [("A", [1, 2])], to: [("A", [0, 2, 1])])
        test(from: [("A", [1, 2])], to: [("A", [0, 2, 1, 3])])
        test(from: [("A", [1, 2])], to: [("A", [0, 2, 8, 1, 3])])
    }

    func testSectionInsertAndRemove() {
        test(from: [("A", [1])], to: [("A", [1]), ("B", [1])])
        test(from: [("A", [1])], to: [("A", [1]), ("B", [1]), ("C", [1])])
        test(from: [("B", [1])], to: [("A", [1]), ("B", [1])])
        test(from: [("C", [1])], to: [("A", [1]), ("B", [1]), ("C", [1])])
        test(from: [("B", [1])], to: [("A", [1]), ("B", [1]), ("C", [1])])
        test(from: [("C", [1]), ("B", [1]), ("A", [1])], to: [("A", [1]), ("B", [1]), ("C", [1])])
    }

    func testSectionAndRowInsertAndRemove() {
        test(from: [("A", [1])], to: [("A", [1, 2]), ("B", [1])])
        test(from: [("A", [2])], to: [("A", [1, 2]), ("B", [1])])
        test(from: [("A", [1, 2, 3])], to: [("A", [3, 2, 1]), ("B", [1])])
        test(from: [("A", [1, 2]), ("B", [3, 4])], to: [("A", [1]), ("B", [2, 3, 4])])
        test(from: [("A", [1]), ("B", [3, 4])], to: [("B", [3])])
    }

    func testIsolated() {
        test(from: [("A", [1]), ("B", [3, 4])], to: [("B", [3])])
    }
}
