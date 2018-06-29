//
//  CollectionDiffTests.swift
//  Form
//
//  Created by Said Sikira on 8/6/17.
//  Copyright © 2017 iZettle. All rights reserved.
//

import XCTest
@testable import Form

/// Applies given changes to a given array and returns resulting array
///
/// - Parameters:
///   - changes: Array of `ChangeStep`
///   - array: Array to apply changes to
/// - Returns: Resulting array
func apply<T: Hashable>(changes: [ChangeStep<T, Int>], to array: [T]) -> [T] {
    var copy = array

    changes.enumerated().forEach { step, change in
        switch change {
        case let .insert(element, index):
            copy.insert(element, at: index)
        case let .delete(_, index):
            copy.remove(at: index)
        case let .move(element, fromIndex, toIndex):
            copy.remove(at: fromIndex)
            copy.insert(element, at: toIndex)
        case let.update(element, index):
            copy[index] = element
        }
    }
    return copy
}

/// Returns changes from the `old` array to the `new` array based on the diffing complexity
func changes<T: Hashable>(from old: [T], to new: [T]) -> [ChangeStep<T, Int>] {
    return old.changes(toBuild: new)
}

func randomizedArray(length: Int) -> [Int] {
    return (1...length).map { _ in Int(arc4random_uniform(UInt32(length))) }
}

class DiffTests: XCTestCase {

    func testZeroChangeCount() {
        XCTAssertEqual([Int]().changes(toBuild: [Int]()).count, 0)
        XCTAssertEqual([0].changes(toBuild: [0]).count, 0)
        XCTAssertEqual(["a", "b"].changes(toBuild: ["a", "b"]).count, 0)
    }

    func testSameElements() {
        testChanges(from: ["a"], to: ["a"])
        testChanges(from: [1, 2, 3, 4], to: [1, 2, 3, 4])
        testChanges(from: [1.0], to: [1.0])
    }

    func testDuplicateElements() {
        let old = ["a", "a", "a"]
        let new = ["a", "a"]

        let changes = old.changes(toBuild: new)

        XCTAssertEqual(changes.count, 1)
    }

    func testSimpleInsert() {
        let old = ["a"]
        let new = ["a", "b"]

        let changes = old.changes(toBuild: new)
        XCTAssertEqual(changes.count, 1)
        XCTAssert(changes[0] == .insert(item: "b", at: 1))
    }

    func testSimpleDelete() {
        let old = ["a", "b", "c", "d"]
        let new = ["b", "c"]

        let changes = old.notFullyOrderedChanges(toBuild: new)

        XCTAssertEqual(changes.count, 2)

        XCTAssert(changes[0] == .delete(item: "a", at: 0))
        XCTAssert(changes[1] == .delete(item: "d", at: 3))
    }

    func testSimpleMove() {
        let old = ["a", "b", "c"]
        let new = ["c", "b", "a"]

        let changes = old.notFullyOrderedChanges(toBuild: new)

        XCTAssertEqual(changes.count, 2)

        XCTAssert(changes[0] == .move(item: "c", from: 2, to: 0))
        XCTAssert(changes[1] == .move(item: "a", from: 0, to: 2))

    }

    func testOrderedMove() {
        let old = ["a", "b", "c"]
        let new = ["c", "b", "a"]

        let changes = old.changes(toBuild: new)

        XCTAssertEqual(changes.count, 4)

        let assumedChanges: [ChangeStep<String, Int>] = [
            .delete(item: "c", at: 2),
            .delete(item: "a", at: 0),
            .insert(item: "c", at: 0),
            .insert(item: "a", at: 2)
        ]

        XCTAssert(changes[0] == assumedChanges[0])
        XCTAssert(changes[1] == assumedChanges[1])
        XCTAssert(changes[2] == assumedChanges[2])
        XCTAssert(changes[3] == assumedChanges[3])
    }

    func testMixed() {
        let old = ["a", "b", "a", "c", "d", "e"]
        let new = ["g", "e", "a", "b"]

        testChanges(from: old, to: new)
        testChanges(from: new, to: old)
    }

    func testMap() {
        let change: ChangeStep = .insert(item: 1.0, at: 0)

        let mapped = change.map { "\($0)" }
        XCTAssert(type(of: mapped) == ChangeStep<String, Int>.self)
        XCTAssert(mapped == .insert(item: "1.0", at: 0))
    }

    func testMapIndex() {
        let change: ChangeStep = .insert(item: 1, at: 0)

        let mapped = change.mapIndex { "\($0)" }

        XCTAssert(type(of: mapped) == ChangeStep<Int, String>.self)
        XCTAssert(mapped == .insert(item: 1, at: "0"))
    }

    func testDiffSpeed() {
        let old = randomizedArray(length: 5000)
        let new = randomizedArray(length: 5000)

        var changes = [ChangeStep<Int, Int>]()

        measure {
            changes = old.changes(toBuild: new)
        }

        XCTAssertEqual(apply(changes: changes, to: old), new)
    }
}

extension DiffTests {
    func testChanges<T: Hashable>(from old: [T], to new: [T]) {
        let changeSteps = changes(from: old, to: new)
        let newArray = apply(changes: changeSteps, to: old)

        XCTAssertEqual(new, newArray)
    }
}
