//
//  TableChange.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-10-12.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

public enum TableChange<Section, Row> {
    case section(ChangeStep<Section, Int>)
    case row(ChangeStep<Row, TableIndex>)
}

public extension Table {
    /// Produces an array of table change steps needed to build `other` table from `self`, which can be used
    /// to update a `UITableView`
    ///
    /// - Parameters:
    ///   - other: Other table instance to compare to
    ///   - sectionIdentifier: Closure returning unique identifier for a given section
    ///   - sectionNeedsUpdate: Closure indicating whether two sections with equal identifiers has any updates.
    ///   - rowIdentifier: Closure returning unique identifier for a given row
    ///   - rowNeedsUpdate: Closure indicating whether two rows with equal identifier has any updates.
    /// - Returns: Array of `TableChange`
    func changes<SectionIdentifier: Hashable, RowIdentifier: Hashable>(toBuild other: Table,
                                                                       sectionIdentifier: (Section) -> SectionIdentifier,
                                                                       sectionNeedsUpdate: (Section, Section) -> Bool,
                                                                       rowIdentifier: (Row) -> RowIdentifier,
                                                                       rowNeedsUpdate: (Row, Row) -> Bool
        ) -> [TableChange<Section, Row>] {

        let sectionChanges = sections.notFullyOrderedChanges(toBuild: other.sections,
                                                             identifier: { sectionIdentifier($0.value) },
                                                             needsUpdate: { sectionNeedsUpdate($0.value, $1.value) })

        var changes: [TableChange<Section, Row>] = sectionChanges.map { .section($0.map { $0.value }) }

        let fromIndices = Set(sections.indices).subtracting(Set(removeIndices(in: sectionChanges))).sorted()
        let toIndices = Set(other.sections.indices).subtracting(Set(insertIndices(in: sectionChanges))).sorted()
        assert(fromIndices.count == toIndices.count)

        for (fromIndex, toIndex) in zip(fromIndices, toIndices) {
            let fromSection = sections[fromIndex]
            let toSection = other.sections[toIndex]

            let rowChanges = fromSection.notFullyOrderedChanges(toBuild: toSection,
                                                                identifier: rowIdentifier,
                                                                needsUpdate: rowNeedsUpdate)

            changes.append(contentsOf: rowChanges.map { change in
                switch change {
                case .insert:
                    return .row(change.mapIndex { TableIndex(section: toIndex, row: $0) })
                case .delete:
                    return .row(change.mapIndex { TableIndex(section: fromIndex, row: $0) })
                case .update:
                    return .row(change.mapIndex { TableIndex(section: fromIndex, row: $0) })
                case .move:
                    return .row(change.mapIndex { TableIndex(section: toIndex, row: $0) })
                }
            })
        }

        return changes
    }
}

public extension RangeReplaceableCollection {
    /// Will move an element at `fromIndex` to `toIndex` by using inserts and removals.
    mutating func moveElement(from fromIndex: Index, to toIndex: Index) {
        if fromIndex == toIndex {
            // Nothing to do
        } else if fromIndex < toIndex {
            insert(self[fromIndex], at: index(after: toIndex))
            remove(at: fromIndex)
        } else {
            let element = remove(at: fromIndex)
            insert(element, at: toIndex)
        }
    }
}

/// Returns indices for remove changes
private func removeIndices<S: Sequence,
    Element,
    Index>(in changes: S) -> [Index]
    where S.Iterator.Element == ChangeStep<Element, Index> {
        return changes.compactMap { change in
            switch change {
            case let .delete(_, index):
                return index
            default: return nil
            }
        }
}

/// Returns indices for insert changes
private func insertIndices<S: Sequence,
    Element,
    Index>(in changes: S) -> [Index]
    where S.Iterator.Element == ChangeStep<Element, Index> {
        return changes.compactMap { change in
            switch change {
            case let .insert(_, index):
                return index
            default: return nil
            }
        }
}
