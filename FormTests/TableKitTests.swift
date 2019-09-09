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
        let tableView = TableKit(table: emptyTable) { _, _ in UITableViewCell() }

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
        let tableView = TableKit(table: emptyTable) { _, _ in UITableViewCell() }

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

    func testTableKitSubscriptionsAreSet() {
        let kit: TableKit! = TableKit(table: Table(rows: [1, 2]), holdIn: nil) { _, _ in UITableViewCell() }
        XCTAssertTrue(kit.dataSource.cellForIndex.isSet)
        XCTAssertTrue(kit.delegate.viewForHeaderInSection.isSet)
        XCTAssertTrue(kit.delegate.viewForFooterInSection.isSet)
    }

    func testTableKitSubscriptionsAreSet_externalBag() {
        let bag = DisposeBag()
        let kit: TableKit! = TableKit(table: Table(rows: [1, 2]), holdIn: bag) { _, _ in UITableViewCell() }
        XCTAssertTrue(kit.dataSource.cellForIndex.isSet)
        XCTAssertTrue(kit.delegate.viewForHeaderInSection.isSet)
        XCTAssertTrue(kit.delegate.viewForFooterInSection.isSet)

        bag.dispose()

        XCTAssertFalse(kit.dataSource.cellForIndex.isSet)
        XCTAssertFalse(kit.delegate.viewForHeaderInSection.isSet)
        XCTAssertFalse(kit.delegate.viewForFooterInSection.isSet)
    }

    func testTableKitNoRetainCycles() {
        var kit: TableKit! = TableKit(table: Table(rows: [1, 2])) { _, _ in UITableViewCell() }
        weak var weakKit = kit
        XCTAssertNotNil(weakKit)
        kit = nil
        XCTAssertNil(weakKit)
    }

    func testTableKitNoRetainCyclesWithBag() {
        var bag: DisposeBag! = DisposeBag()
        weak var weakBag = bag

        var kit: TableKit! = TableKit(table: Table(rows: [1, 2]), holdIn: weakBag) { _, _ in UITableViewCell() }
        weak var weakKit = kit
        XCTAssertNotNil(weakKit)
        bag = nil
        kit = nil
        XCTAssertNil(weakKit)
        XCTAssertNil(bag)
    }
}
