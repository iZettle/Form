//
//  ParentChildRelationalTests.swift
//  FormTests
//
//  Created by Måns Bernhardt on 2018-05-24.
//  Copyright © 2018 iZettle. All rights reserved.
//

import XCTest
import Form

class ParentChildRelationalTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = tree1 // Build tree
    }

    func testAllAncestors() {
        XCTAssertEqual(Array(tree3.allAncestors), [tree2, tree1])
    }

    func testRootParent() {
        XCTAssertEqual(tree3.rootParent, tree1)
    }

    func testAllAncestorsDescendantsOf() {
        XCTAssertNil(tree3.allAncestors(descendantsOf: tree3))
        XCTAssertEqual(tree3.allAncestors(descendantsOf: tree2).map(Array.init), [])
        XCTAssertEqual(tree3.allAncestors(descendantsOf: tree1).map(Array.init), [tree2])
        XCTAssertEqual(tree5.allAncestors(descendantsOf: tree3).map(Array.init), [tree4])
    }

    func testAllDescendants() {
        XCTAssertEqual(Array(tree1.allDescendants), [tree2, tree3, tree4, tree5])
        XCTAssertEqual(Array(tree5.allDescendants), [])
        XCTAssertEqual(Array(tree4.allDescendants), [tree5])
        print(tree10.allDescendants.map { $0.value })
        XCTAssertEqual(Set(tree10.allDescendants.map { $0.value }), Set([100, 1000, 101, 102, 1020, 1021]))
    }
}

final class Tree: ParentChildRelational, Equatable, CustomStringConvertible {
    let value: Int
    var parent: Tree?
    let children: [Tree]

    init(_ value: Int, _ children: Tree...) {
        self.value = value
        self.children = children
        for child in children {
            child.parent = self
        }
    }

    static func == (lhs: Tree, rhs: Tree) -> Bool {
        return lhs === rhs
    }

    var description: String { return "\(value)" }
}

let tree5 = Tree(5)
let tree4 = Tree(4, tree5)
let tree3 = Tree(3, tree4)
let tree2 = Tree(2, tree3)
let tree1 = Tree(1, tree2)

let tree10 = Tree(10, Tree(100, Tree(1000)), Tree(101), Tree(102, Tree(1020), Tree(1021)))
