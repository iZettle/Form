//
// Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Flow
@testable import Form

class CollectionKitTests: XCTestCase {
    func testCollectionKitSubscriptionsAreSet() {
        let kit: CollectionKit! = CollectionKit(table: Table(rows: [1, 2]), layout: UICollectionViewFlowLayout()) { _, _, _ in UICollectionViewCell() }
        XCTAssertTrue(kit.dataSource.cellForIndex.isSet)
    }

    func testCollectionKitSubscriptionsAreSet_externalBag() {
        let bag = DisposeBag()
        let kit: TableKit! = TableKit(table: Table(rows: [1, 2]), holdIn: bag) { _, _ in UITableViewCell() }
        XCTAssertTrue(kit.dataSource.cellForIndex.isSet)

        bag.dispose()

        XCTAssertFalse(kit.dataSource.cellForIndex.isSet)
    }

    func testCollectionKitNoRetainCycles() {
        var kit: CollectionKit! = CollectionKit(table: Table(rows: [1, 2]), layout: UICollectionViewFlowLayout()) { _, _, _ in UICollectionViewCell() }
        weak var weakKit = kit
        XCTAssertNotNil(weakKit)
        kit = nil
        XCTAssertNil(weakKit)
    }

    func testCollectionKitNoRetainCyclesWithBag() {
        var bag: DisposeBag! = DisposeBag()
        weak var weakBag = bag

        var kit: CollectionKit! = CollectionKit(table: Table(rows: [1, 2]), layout: UICollectionViewFlowLayout(), holdIn: weakBag) { _, _, _ in UICollectionViewCell() }
        weak var weakKit = kit
        XCTAssertNotNil(weakKit)
        bag = nil
        kit = nil
        XCTAssertNil(weakKit)
        XCTAssertNil(bag)
    }
}
