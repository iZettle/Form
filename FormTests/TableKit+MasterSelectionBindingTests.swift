//
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Flow
@testable import Form

class TableKitMasterSelectionBindingTests: XCTestCase {
    func testStateAfterBinding_noInitialSelection() {
        let kit = createTableKit(numberOfRows: 10, visibleRows: 5)

        let signal = ReadWriteSignal<TableIndex?>(nil)

        XCTAssertNil(kit.view.indexPathForSelectedRow)
        let disposable = signal.bindTo(kit, animateSelectionChange: false, select: { _ in })
        XCTAssertNil(kit.view.indexPathForSelectedRow)

        disposable.dispose()
    }

    func testStateAfterBinding_initialSelection() {
        let kit = createTableKit(numberOfRows: 10, visibleRows: 5)

        let index = TableIndex(section: 0, row: 1)
        let signal = ReadWriteSignal<TableIndex?>(index)

        XCTAssertNil(kit.view.indexPathForSelectedRow)
        let disposable = signal.bindTo(kit, animateSelectionChange: false, select: { _ in })
        XCTAssertEqual(kit.view.indexPathForSelectedRow, IndexPath(row: 1, section: 0))

        disposable.dispose()
    }

    func testStateAfterSelectionChange_withinBounds() {
        let kit = createTableKit(numberOfRows: 10, visibleRows: 5)

        let index = TableIndex(section: 0, row: 1)
        let signal = ReadWriteSignal<TableIndex?>(index)
        let disposable = signal.bindTo(kit, animateSelectionChange: false, select: { _ in })

        signal.value = TableIndex(section: 0, row: 9)
        XCTAssertEqual(kit.view.indexPathForSelectedRow, IndexPath(row: 9, section: 0))

        disposable.dispose()
    }

    func testStateAfterSelectionChange_outOfBounds() {
        let kit = createTableKit(numberOfRows: 10, visibleRows: 5)

        let index = TableIndex(section: 0, row: 1)
        let signal = ReadWriteSignal<TableIndex?>(index)
        let disposable = signal.bindTo(kit, animateSelectionChange: false, select: { _ in })

        signal.value = TableIndex(section: 0, row: 10)
        XCTAssertEqual(kit.view.indexPathForSelectedRow, IndexPath(row: 1, section: 0))

        disposable.dispose()
    }

    func testStateAfterRemovingSelection() {
        let kit = createTableKit(numberOfRows: 10, visibleRows: 5)

        let index = TableIndex(section: 0, row: 1)
        let signal = ReadWriteSignal<TableIndex?>(index)

        let disposable = signal.bindTo(kit, animateSelectionChange: false, select: { _ in })
        XCTAssertNotNil(kit.view.indexPathForSelectedRow)

        signal.value = nil
        XCTAssertNil(kit.view.indexPathForSelectedRow)

        disposable.dispose()
    }

    func testThatSelectionChangeRevealsRow() {
        let kit = createTableKit(numberOfRows: 10, visibleRows: 5)

        let index = TableIndex(section: 0, row: 2)
        let signal = ReadWriteSignal<TableIndex?>(index)
        let disposable = signal.bindTo(kit, animateSelectionChange: false, select: { _ in })

        kit.view.scrollToBottom(animated: false)
        XCTAssertFalse(kit.view.areSelectedRowsVisible)

        signal.value = TableIndex(section: 0, row: 1)
        XCTAssertTrue(kit.view.areSelectedRowsVisible)

        disposable.dispose()
    }

    func testThatSameSelectionDoesNotRevealRow() {
        let kit = createTableKit(numberOfRows: 10, visibleRows: 5)

        let index = TableIndex(section: 0, row: 1)
        let signal = ReadWriteSignal<TableIndex?>(index)
        let disposable = signal.bindTo(kit, animateSelectionChange: false, select: { _ in })

        kit.view.scrollToBottom(animated: false)
        XCTAssertFalse(kit.view.areSelectedRowsVisible)

        signal.value = index
        XCTAssertFalse(kit.view.areSelectedRowsVisible)

        disposable.dispose()
    }

    func testThatSelectingRowWithNoVisibleRowsDoesNotScroll() {
        let bag = DisposeBag()
        let kit = createTableKit(numberOfRows: 10, visibleRows: 0)

        let signal = ReadWriteSignal<TableIndex?>(nil)
        bag += signal.bindTo(kit, animateSelectionChange: false, select: { _ in })

        let shouldNotScroll = XCTestExpectation(description: "table should not have scrolled")
        shouldNotScroll.isInverted = true

        bag += kit.view.signal(for: \.contentOffset)
            .filter { $0 != .zero }
            .onValue { _ in shouldNotScroll.fulfill() }

        let newSelection = TableIndex(section: 0, row: 0)
        signal.value = newSelection

        XCTAssert(kit.view.indexPathForSelectedRow == IndexPath(newSelection, in: kit.table))

        let timeout: TimeInterval = 0.1
        wait(for: [shouldNotScroll], timeout: timeout)
        bag.dispose(after: timeout)
    }

    func createTableKit(numberOfRows: Int, visibleRows: Int) -> TableKit<EmptySection, Int> {
        let kit: TableKit! = TableKit(table: Table(rows: Array(1...numberOfRows))) { _, _ in UITableViewCell() }
        kit.view.frame.size = kit.view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        kit.view.frame.size.height = (kit.view.visibleCells.first?.frame.size.height ?? 0) * CGFloat(visibleRows)
        return kit
    }
}

extension UITableView {
    var areSelectedRowsVisible: Bool {
        let selectedRows = Set(indexPathsForSelectedRows ?? [])
        let visibleRows = Set(indexPathsForVisibleRows ?? [])
        return selectedRows.isSubset(of: visibleRows)
    }
}
