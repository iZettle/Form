//
//  Table.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-01.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

/// A collection of rows organized into sections useful when populating table and collection views.
public struct Table<Section, Row> {
    private let sectionStartIndex: Int // Skipping empty sections
    private let sectionEndIndex: Int // Skipping empty sections
    private var _sections: [TableSection<Section, Row>]

    public let count: Int

    private init(sections: [TableSection<Section, Row>]) {
        count = sections.reduce(0) { $0 + $1.count }
        _sections = sections
        let nonEmptyIndices = zip(sections.indices, sections).filter { !$1.slice.isEmpty }.map { $0.0 }
        sectionStartIndex = nonEmptyIndices.first ?? sections.startIndex
        sectionEndIndex = nonEmptyIndices.last.map { $0 + 1 } ?? (nonEmptyIndices.isEmpty ? sections.startIndex : sections.endIndex)
    }
}

public extension Table {
    var sections: [TableSection<Section, Row>] {
        get { return _sections }
        set { self = Table(sections: newValue) }
    }

    mutating func removeEmptySections() {
        sections = sections.filter { !$0.isEmpty }
    }
}

public extension Table {
    init() {
        self.init(sections: [])
    }

    /// Creates a new instance from a sequence `sections` containing section and rows tuples:
    ///
    ///     Table(sections: [("1", [0, 1, 2]), ("2", [3, 4])])
    init<S: Sequence, I: Sequence>(sections: S) where S.Iterator.Element == (Section, I), I.Iterator.Element == Row {
        var rows = [Row]()
        var sectionPairs = [(Section, Range<Int>)]()
        for section in sections {
            let offset = rows.count
            rows.append(contentsOf: section.1)
            sectionPairs.append((section.0, offset..<rows.count))
        }
        self.init(sections: sectionPairs.map { TableSection(value: $0, slice: rows[$1]) })
    }

    /// Creates a new instance from a `rows` sequence divided by sections based on the section value returned from `sectionValue´
    /// The table is orderd by `rows` and new sections are created when `sectionValue` returns a non nil section.
    /// - Note: sectionValue for the first row must return a non nil section.
    ///
    ///     Table(rows: 0..<100) { row in row%5 == 0 ? "\(row/5)" : nil }
    init<S: Sequence>(rows: S, sectionValue: (Row) -> Section?) where S.Iterator.Element == Row {
        let rows = Array(rows)

        var prev: Section?
        var sectionStart = 0
        var sections = [(Section, Range<Int>)]()
        for (index, row) in rows.enumerated() {
            let sectionValue = sectionValue(row)
            precondition(index > 0 || sectionValue != nil, "sectionValue must return a non nil section for the first element")
            if let prev = prev, sectionValue != nil {
                sections.append((prev, sectionStart..<index))
                sectionStart = index
            }
            prev = sectionValue ?? prev
        }

        if let prev = prev {
            sections.append((prev, sectionStart..<rows.endIndex))
        }

        self.init(sections: sections.map { TableSection(value: $0, slice: rows[$1]) })
    }

    init(_ slice: Slice<Table>) {
        var result = slice.base

        result.replaceSubrange(slice.endIndex..., with: [])
        result.replaceSubrange(..<slice.startIndex, with: [])

        self = result
    }
}

public typealias EmptySection = Void

public extension Table where Section == EmptySection {
    /// Creates a new instance from a `rows` sequence within a single empty section.
    ///
    ///     Table(rows: [0, 1, 2])
    init<S: Sequence>(rows: S) where S.Iterator.Element == Row {
        self.init(sections: [(EmptySection(), Array(rows))])
    }
}

public extension Table where Section: Equatable {
    /// Creates a new instance from a `rows` sequence divided by sections based on the section value returned from `sectionValue´
    /// The table is orderd by `rows` and new sections are created when the section from `sectionValue` differs from the previous section.
    ///
    ///     Table(rows: 0..<100) { row in "\(row/5)" }
    init<S: Sequence>(rows: S, sectionValue: (Row) -> Section) where S.Iterator.Element == Row {
        var prev: Section?
        self.init(rows: rows) { row -> Section? in
            let section = sectionValue(row)
            guard section != prev else { return nil }
            prev = section
            return section
        }
    }
}

extension Table: MutableCollection {
    public typealias Index = TableIndex
    public typealias Iterator = IndexingIterator<Table>

    public var startIndex: Index { return TableIndex(section: sectionStartIndex, row: 0) }
    public var endIndex: Index { return TableIndex(section: sectionEndIndex, row: 0) }

    public subscript (position: Index) -> Row {
        get { return sections[position.section][position.row] }
        set { sections[position.section][position.row] = newValue }
    }

    public func index(after i: Index) -> Index {
        guard i.section < sections.count else { return endIndex }
        let section = sections[i.section]
        var next = i
        next.row += 1
        guard next.row < section.count else {
            var section = i.section
            repeat {
                section += 1
                guard section < sections.count else { return endIndex }
            } while sections[section].isEmpty
            return Index(section: section, row: 0)
        }
        return next
    }
}

extension Table: BidirectionalCollection {
    public func index(before i: Index) -> Index {
        var prev = i
        prev.row -= 1
        guard prev.row >= 0 else {
            var section = i.section - 1
            while sections[section].isEmpty { section -= 1 }
            return Index(section: section, row: sections[section].count - 1)
        }
        return prev
    }
}

extension Table: RangeReplaceableCollection {
    public mutating func replaceSubrange<C>(_ subrange: Range<TableIndex>, with newElements: C) where C: Collection, C.Iterator.Element == Row {
        var sections: [(Section, [Row])] = self.sections.map { return ($0.value, Array($0.slice)) }
        precondition(!sections.isEmpty)

        var realEndIndex = self.index(before: self.endIndex)
        realEndIndex.row += 1
        let subrange = subrange.isEmpty && subrange.lowerBound == self.endIndex ? Range<TableIndex>(uncheckedBounds: (lower: realEndIndex, upper: realEndIndex)) : subrange

        let lowerBound = subrange.lowerBound
        let upperSection = subrange.upperBound.row == 0 && !subrange.isEmpty ? subrange.upperBound.section - 1 : subrange.upperBound.section
        let upperBound = subrange.upperBound.row == 0 && !subrange.isEmpty ? TableIndex(section: subrange.upperBound.section - 1, row: self.sections[upperSection].count) : subrange.upperBound

        let sectionRange = lowerBound.section...upperBound.section

        let oldSections = Array(sections[sectionRange])

        let lowerElements = oldSections.first?.1[0..<lowerBound.row] ?? []
        let upperElements: ArraySlice<Row> = oldSections.last.flatMap { $0.1[upperBound.row..<$0.1.count] } ?? []

        let newSectionElements = Array(lowerElements + newElements + upperElements)
        sections.replaceSubrange(Range<Int>(sectionRange), with: [(oldSections[0].0, newSectionElements)])

        self = Table(sections: sections)
    }
}

extension Table: CustomStringConvertible {
    public var description: String {
        var result = "["
        for section in sections {
            result += "(\(section.value), [\n"
            for row in section {
                result += "\t\(row),\n"
            }
            result += "]),"
        }
        result += "]"
        return result
    }
}

/// Section used by Table
public struct TableSection<Section, Row> {
    public let value: Section
    fileprivate var slice: ArraySlice<Row>
}

extension TableSection: MutableCollection {
    public typealias Index = Int

    public var startIndex: Index { return 0 }
    public var endIndex: Index { return slice.count }
    public var count: Int { return slice.count }

    public subscript (position: Index) -> Row {
        get { return slice[slice.startIndex + position] }
        set { slice[slice.startIndex + position] = newValue }
    }

    public func index(after i: Index) -> Index { return i + 1 }
    public func index(before i: Index) -> Index { return i - 1 }
}

/// Index used by Table
public struct TableIndex {
    public var section: Int
    public var row: Int

    public init(section: Int, row: Int) {
        self.section = section
        self.row = row
    }
}

extension TableIndex: Comparable {
    public static func == (lhs: TableIndex, rhs: TableIndex) -> Bool {
        return lhs.section == rhs.section && lhs.row == rhs.row
    }

    public static func < (lhs: TableIndex, rhs: TableIndex) -> Bool {
        return lhs.section == rhs.section ? lhs.row < rhs.row : lhs.section < rhs.section
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(section)
        hasher.combine(row)
    }
}

extension Table {
    public subscript (position: IndexPath) -> Row? { return TableIndex(position, in: self).map { self[$0] } }
}

extension Table: Equatable where Section: Equatable, Row: Equatable {
    public static func == (lhs: Table, rhs: Table) -> Bool {
        return lhs.sections == rhs.sections
    }
}

extension TableSection: Equatable where Section: Equatable, Row: Equatable {
    public static func == (lhs: TableSection, rhs: TableSection) -> Bool {
        return lhs.value == rhs.value && lhs.slice == rhs.slice
    }
}
