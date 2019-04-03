//
//  TableTest.swift
//  Form
//
//  Created by Emmanuel Garnier on 28/09/16.
//  Copyright © 2016 iZettle. All rights reserved.
//

import XCTest
import Form

class TableTests: XCTestCase {

    func testIndexOf() {

        // [0, 1, 2]
        // [3, 4]
        // [5]
        // [6, 7, 8, 9]
        let table = Table(sections: [
            ((), [0, 1, 2]),
            ((), [3, 4]),
            ((), [5]),
            ((), [6, 7, 8, 9]),
                          ])

        var index = table.firstIndex(of: 2)!
        XCTAssertEqual(index.section, 0)
        XCTAssertEqual(index.row, 2)

        index = table.firstIndex(of: 3)!
        XCTAssertEqual(index.section, 1)
        XCTAssertEqual(index.row, 0)

        index = table.firstIndex(of: 5)!
        XCTAssertEqual(index.section, 2)
        XCTAssertEqual(index.row, 0)

        index = table.firstIndex(of: 7)!
        XCTAssertEqual(index.section, 3)
        XCTAssertEqual(index.row, 1)

        index = table.firstIndex(of: 9)!
        XCTAssertEqual(index.section, 3)
        XCTAssertEqual(index.row, 3)
    }

    func testEmptyIndexing() {
//        let dict = Dictionary<String, Int>()
//        print(dict.startIndex)
//        print(dict.endIndex)
//        print(dict.index(after: dict.startIndex))
//        XCTAssertEqual(dict.index(after: dict.startIndex), dict.endIndex)

        let table = Table<Int, ()>()
        print(table.startIndex, table.endIndex)
        XCTAssertEqual(table.index(after: table.startIndex), table.endIndex)
    }

    func testRemoveObject() {
        // [0, 1, 2]
        // [3, 4]
        // [5]
        // [6, 7, 8, 9]
        let table = Table(sections: [
            ("1", [0, 1, 2]),
            ("8", [3, 4]),
            ("4", [5]),
            ("0", [6, 7, 8, 9]),
            ])

        var newTable = table
        newTable.remove(at: TableIndex(section: 1, row: 0))
        XCTAssertEqual(newTable[TableIndex(section: 1, row: 0)], 4)

        newTable = table
        newTable.remove(at: TableIndex(section: 1, row: 1))
        XCTAssertEqual(newTable.sections[1].count, 1)
        XCTAssertEqual(newTable[TableIndex(section: 1, row: 0)], 3)

        newTable = table
        newTable.remove(at: TableIndex(section: 2, row: 0))
        XCTAssertEqual(newTable.sections[2].count, 0)

        newTable = table
        newTable.remove(at: TableIndex(section: 3, row: 3))
        XCTAssertEqual(newTable.sections[3].count, 3)
        XCTAssertEqual(newTable[TableIndex(section: 3, row: 2)], 8)
    }

    func testAddObject() {
        // [0, 1, 2]
        // [3, 4]
        // [5]
        // [6, 7, 8, 9]
        let table = Table(sections: [
            ("1", [0, 1, 2]),
            ("8", [3, 4]),
            ("4", [5]),
            ("0", [6, 7, 8, 9]),
            ])

        var newTable = table
        newTable.insert(10, at: TableIndex(section: 1, row: 0))
        XCTAssertEqual(newTable.sections[1].count, 3)
        XCTAssertEqual(newTable[TableIndex(section: 1, row: 0)], 10)

        newTable = table
        newTable.insert(10, at: TableIndex(section: 0, row: 2))
        XCTAssertEqual(newTable.sections[0].count, 4)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 2)], 10)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 3)], 2)

        newTable = table
        newTable.insert(10, at: TableIndex(section: 0, row: 3))
        XCTAssertEqual(newTable.sections[0].count, 4)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 2)], 2)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 3)], 10)

        newTable = table
        newTable.insert(10, at: TableIndex(section: 4, row: 0))
        XCTAssertEqual(newTable.sections.count, 4)
        XCTAssertEqual(newTable[TableIndex(section: 3, row: 4)], 10)
    }

    func testMutating() {
        // [0, 1, 2]
        // [3, 4]
        // [5]
        // [6, 7, 8, 9]
        let table = Table(sections: [
            ("1", [0, 1, 2]),
            ("8", [3, 4]),
            ("4", [5]),
            ("0", [6, 7, 8, 9]),
            ])

        var newTable = table
        newTable.sections[0][1] = 5
        XCTAssertEqual(newTable.sections[0][1], 5)

        let index1 = newTable.index(newTable.startIndex, offsetBy: 2)
        let index2 = newTable.index(newTable.startIndex, offsetBy: 5)

        var subTable = Table(newTable[index1..<index2])
        XCTAssertEqual(subTable.count, 3)
        XCTAssertEqual(subTable.first, 2)
        XCTAssertEqual(subTable.last, 4)

        XCTAssertEqual(subTable.sections.count, 3)
        subTable.removeEmptySections()
        XCTAssertEqual(subTable.sections.count, 2)

        newTable.removeSubrange(index1..<index2)
        XCTAssertEqual(newTable.count, table.count-3)
        XCTAssertEqual(newTable.sections.count, 3)
    }

    func testReplaceRange() {
        // [0, 1, 2]
        // [3, 4]
        // [5]
        // [6, 7, 8, 9]
        let table = Table(sections: [
            ("1", [0, 1, 2]),
            ("8", [3, 4]),
            ("4", [5]),
            ("0", [6, 7, 8, 9]),
            ])

        var newTable = table
        newTable.replaceSubrange(TableIndex(section: 0, row: 1)...TableIndex(section: 0, row: 2), with: [91, 92, 93, 94])
        XCTAssertEqual(newTable.sections[0].count, 5)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 0)], 0)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 4)], 94)

        newTable = table
        newTable.replaceSubrange(TableIndex(section: 0, row: 2)...TableIndex(section: 2, row: 0), with: [91, 92, 93, 94])
        XCTAssertEqual(newTable.sections.count, 2)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 2)], 91)
        XCTAssertEqual(newTable[TableIndex(section: 0, row: 5)], 94)
    }

    func testIndicies() {
        var table = Table<Int, Int>()
        XCTAssertEqual(table.indices.count, 0)

        table = Table(sections: [(1, [])])
        XCTAssertEqual(table.indices.count, 0)

        table = Table(sections: [(1, [1])])
        XCTAssertEqual(Array(table.indices), [TableIndex(section: 0, row: 0)])

        table = Table(sections: [(1, []), (2, [])])
        XCTAssertEqual(table.indices.count, 0)

        table = Table(sections: [(1, []), (2, [0])])
        XCTAssertEqual(Array(table.indices), [TableIndex(section: 1, row: 0)])

        table = Table(sections: [(1, []), (2, [0]), (3, [])])
        XCTAssertEqual(Array(table.indices), [TableIndex(section: 1, row: 0)])

        table = Table(sections: [(1, []), (2, [0]), (3, []), (4, [0]), (5, [])])
        XCTAssertEqual(Array(table.indices), [TableIndex(section: 1, row: 0), TableIndex(section: 3, row: 0)])

    }
}
