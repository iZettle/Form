// 
// Copyright © 2019 iZettle. All rights reserved.
// 

import XCTest
import Flow
@testable import Form

class TableKitTests: XCTestCase {

    func testEmptyStateView_setNewView_oldViewIsRemoved() {
        let bag = DisposeBag()
        let emptyTable: Table<Int, Int> = Table(sections: [(1, [])])
        let tableView = TableKit(table: emptyTable, bag: bag) { _, _ in UITableViewCell() }

        let oldEmptyStateView = UIView()
        bag += tableView.viewForEmptyTable(fadeDuration: 0).set { _ in
            return oldEmptyStateView
        }

        XCTAssertNotNil(oldEmptyStateView.superview)

        let newEmptyStateView = UIView()
        bag += tableView.viewForEmptyTable(fadeDuration: 0).set { _ in
            return newEmptyStateView
        }
        let exp = expectation(description: "thingy")
        XCTAssertNotNil(newEmptyStateView.superview)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if oldEmptyStateView.superview == nil {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func testEmptyStateView_setNewView_oldViewIsRemoved_NoCache() {
        let bag = DisposeBag()
        let emptyTable: Table<Int, Int> = Table(sections: [(1, [])])
        let tableView = TableKit(table: emptyTable, bag: bag) { _, _ in UITableViewCell() }

        let oldEmptyStateView = UIView()
        let viewForEmptyTable = tableView.viewForEmptyTable()
        bag += viewForEmptyTable.set { _ in
            return oldEmptyStateView
        }

        XCTAssertNotNil(oldEmptyStateView.superview)

        let newEmptyStateView = UIView()
        bag += viewForEmptyTable.set { _ in
            return newEmptyStateView
        }

        XCTAssertNotNil(newEmptyStateView.superview)
        XCTAssertNil(oldEmptyStateView.superview)
    }

}
