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

        for insertedSectionIndex in Set(insertIndices(in: sectionChanges)) {
            let toSection = other.sections[insertedSectionIndex]
            changes += toSection.enumerated().map { rowIndex, section in .row(.insert(item: section, at: TableIndex(section: insertedSectionIndex, row: rowIndex))) }
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

public extension Table {
    mutating func apply(_ changes: [TableChange<Section, Row>]) {

        let sortedChanges = changes.sortedForBatchUpdate()

        var flatTable: [(section: Section, rows: [Row])] = sections.map { ($0.value, Array($0)) }

        for change in sortedChanges {
            switch change {
            case let .section(.insert(item, index)): flatTable.insert((section: item, rows: []), at: index)
            case let .section(.delete(_, index)): flatTable.remove(at: index)
            case let .section(.update(item, index)): flatTable[index].section = item
            case .section(.move): break // no moves
            case let .row(.insert(item, index)): flatTable[index.section].rows.insert(item, at: index.row)
            case let .row(.delete(_, index)): flatTable[index.section].rows.remove(at: index.row)
            case let .row(.update(item, index)): flatTable[index.section].rows[index.row] = item
            case .row(.move): break // no moves
            }
        }

        self = Table(sections: flatTable)
    }
}

private extension Collection {
    /// Sorts a Collection of `ChangeStep`s to have deletes coming first
    func sortedForBatchUpdate<Section, Row>() -> [TableChange<Section, Row>] where Element == TableChange<Section, Row> {
        var insertions = [TableChange<Section, Row>]()
        var deletions = [TableChange<Section, Row>]()
        var updates = [TableChange<Section, Row>]()

        for change in self {
            switch change {
            case .section(.delete): deletions.append(change)
            case .row(.delete): deletions.append(change)
            case .section(.insert): insertions.append(change)
            case .row(.insert): insertions.append(change)
            case .section(.update): updates.append(change)
            case .row(.update): updates.append(change)
            case let .section(.move(item, fromIndex, toIndex)):
                deletions.append(.section(.delete(item: item, at: fromIndex)))
                insertions.append(.section(.insert(item: item, at: toIndex)))
            case let .row(.move(item, fromIndex, toIndex)):
                deletions.append(.row(.delete(item: item, at: fromIndex)))
                insertions.append(.row(.insert(item: item, at: toIndex)))

            }
        }
        deletions.sort {
            switch ($0, $1) {
            case let (.section(leftStep), .section(rightStep)): return leftStep.index > rightStep.index
            case let (.row(leftStep), .row(rightStep)): return leftStep.index > rightStep.index
            case (.section, .row): return false
            case (.row, .section): return true
            }
        }
        insertions.sort {
            switch ($0, $1) {
            case let (.section(leftStep), .section(rightStep)): return leftStep.index < rightStep.index
            case let (.row(leftStep), .row(rightStep)): return leftStep.index < rightStep.index
            case (.section, .row): return true
            case (.row, .section): return false
            }
        }

        // Deletes and Updates are processed before inserts in batch operations. This means the indexes for the deletions are processed relative to the indexes of the collection view’s state before the batch operation, and the indexes for the insertions are processed relative to the indexes of the state after all the deletions in the batch operation.
        let sortedChanges = updates + deletions + insertions
        return sortedChanges
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
