//
//  Collection+Changes.swift
//  Form
//
//  Created by Said Sikira on 8/5/17.
//  Copyright © 2017 iZettle. All rights reserved.
//

/// Defines step in a diffing process
public enum ChangeStep<Item, Index> {
    case insert(item: Item, at: Index)
    case delete(item: Item, at: Index)
    case move(item: Item, from: Index, to: Index)
    case update(item: Item, at: Index)
}

public extension Collection where Index == Int {
    /// Returns an array of change steps needed to build `other` from `self`.
    ///
    /// - Parameters:
    ///   - identifier: Unique value representing the identity for a specific element.
    ///             This will be use to generate `ChangeStep` inserts, deletes and moves
    ///   - needsUpdate: Closure indicating whether two elements with the equal identifier needs to be updated
    ///             This will generate `.update` changes. Defaults to return `false`.
    func changes<Identifier: Hashable>(toBuild other: Self,
                                       identifier: (Element) -> Identifier,
                                       needsUpdate: (Element, Element) -> Bool = { _, _ in false }) -> [ChangeStep<Element, Int>] {
        typealias Change = ChangeStep<Element, Index>

        let changes = notFullyOrderedChanges(toBuild: other, identifier: identifier, needsUpdate: needsUpdate)

        var insertions = [Change]()
        var deletions = [[Change]](repeating: [], count: count)
        var updates = [Change]()

        for change in changes {
            switch change {
            case .insert:
                insertions.append(change)
            case let .delete(_, index):
                deletions[index].append(change)
            case let .move(item, fromIndex, toIndex):
                deletions[fromIndex].append(.delete(item: item, at: fromIndex))
                insertions.append(.insert(item: item, at: toIndex))
            case .update:
                updates.append(change)
            }
        }

        return deletions.compactMap { $0.first }.reversed() + updates + insertions
    }
}

public extension Collection where Index == Int, Element: Hashable {
    /// Returns an array of change steps needed to build `other` from `self`.
    func changes(toBuild other: Self) -> [ChangeStep<Element, Int>] {
        return changes(toBuild: other, identifier: { $0 }, needsUpdate: !=)
    }
}

public extension Collection where Index == Int, Element: AnyObject {
    /// Returns an array of change steps needed to build `other` from `self`.
    ///   - needsUpdate: Closure indicating whether two elements with the equal identifier needs to be updated
    ///             This will generate `.update` changes. Defaults to return `false`.
    func changes(toBuild other: Self, needsUpdate: (Element, Element) -> Bool = { _, _ in false }) -> [ChangeStep<Element, Int>] {
        return changes(toBuild: other, identifier: ObjectIdentifier.init, needsUpdate: needsUpdate)
    }
}

extension ChangeStep: Equatable where Item: Equatable, Index: Equatable {
    public static func == (lhs: ChangeStep<Item, Index>, rhs: ChangeStep<Item, Index>) -> Bool {
        switch (lhs, rhs) {
        case (.insert(let lElement, let lIndex),
              .insert(let rElement, let rIndex)):
            return lElement == rElement
                && lIndex == rIndex

        case (.delete(let lElement, let lIndex),
              .delete(let rElement, let rIndex)):
            return lElement == rElement
                && lIndex == rIndex

        case (.move(let lElement, let lFromIndex, let lToIndex),
              .move(let rElement, let rFromIndex, let rToIndex)):
            return lElement == rElement
                && lFromIndex == rFromIndex
                && lToIndex == rToIndex

        case (.update(let lElement, let lIndex),
              .update(let rElement, let rIndex)):
            return lElement == rElement
                && lIndex == rIndex

        default:
            return false
        }
    }
}

extension ChangeStep: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .insert(item, index):
            return "Inserting '\(item)' at '\(index)"
        case let .delete(item, index):
            return "Deleting '\(item)' at '\(index)"
        case let .move(item, fromIndex, toIndex):
            return "Moving '\(item)' from index '\(fromIndex)' to '\(toIndex)'"
        case let .update(item, index):
            return "Updating '\(item)' at '\(index)'"
        }
    }
}

extension Collection where Index == Int {
    // Table and collection view will order changes of the same type so we don't need to use the fully ordered version for these.
    func notFullyOrderedChanges<Identifier: Hashable>(toBuild other: Self,
                                                      identifier: (Element) -> Identifier,
                                                      needsUpdate: (Element, Element) -> Bool) -> [ChangeStep<Element, Int>] {

        var table = [Identifier: Symbol]()
        var oldEntries = [Entry]()
        var newEntries = [Entry]()

        for item in other {
            let key = identifier(item)

            let entry = table[key] ?? Symbol()
            table[key] = entry
            entry.newCounter = entry.newCounter.incremented
            newEntries.append(.symbol(entry))
        }

        for (index, item) in enumerated() {
            let key = identifier(item)

            let entry = table[key] ?? Symbol()
            table[key] = entry
            entry.oldCounter = entry.oldCounter.incremented
            entry.oldIndexes.append(index)
            oldEntries.append(.symbol(entry))
        }

        for (index, item) in newEntries.enumerated() {
            if case .symbol(let entry) = item, entry.occursInBoth {
                guard !entry.oldIndexes.isEmpty else {
                    continue
                }

                let oldIndex = entry.oldIndexes.removeFirst()
                newEntries[index] = .index(oldIndex)
                oldEntries[oldIndex] = .index(index)
            }
        }

        var i = 1
        while i < newEntries.count - 1 {
            if case .index(let j) = newEntries[i], j + 1 < oldEntries.count {
                if case .symbol(let newEntry) = newEntries[i + 1],
                    case .symbol(let oldEntry) = oldEntries[j + 1],
                    newEntry === oldEntry {
                    newEntries[i + 1] = .index(j + 1)
                    oldEntries[j + 1] = .index(i + 1)
                }
            }
            i = i + 1
        }

        i = newEntries.count - 1
        while i > 0 {
            if case .index(let j) = newEntries[i], j - 1 >= 0 {
                if case .symbol(let newEntry) = newEntries[i - 1],
                    case .symbol(let oldEntry) = oldEntries[j - 1],
                    newEntry === oldEntry {

                    newEntries[i - 1] = .index(j - 1)
                    oldEntries[j - 1] = .index(i - 1)
                }
            }
            i = i - 1
        }

        var steps = [ChangeStep<Element, Index>]()

        var deleteOffsets = Array(repeating: 0, count: count)
        var runningOffset = 0
        for (index, item) in oldEntries.enumerated() {
            deleteOffsets[index] = runningOffset
            if case .symbol = item {
                steps.append(.delete(item: self[index], at: index))
                runningOffset = runningOffset + 1
            }
        }

        runningOffset = 0

        for (index, item) in newEntries.enumerated() {
            switch item {
            case .symbol:
                steps.append(.insert(item: other[index], at: index))
                runningOffset = runningOffset + 1
            case .index(let oldIndex):
                let deleteOffset = deleteOffsets[oldIndex]
                if (oldIndex - deleteOffset + runningOffset) != index {
                    steps.append(.move(item: other[index], from: oldIndex, to: index))
                } else if needsUpdate(self[oldIndex], other[index]) {
                    steps.append(.update(item: other[index], at: oldIndex))
                }
            }
        }

        return steps
    }
}

extension Collection where Index == Int, Element: Hashable {
    // Table and collection view will order changes of the same type so we don't need to use the fully ordered version for these.
    func notFullyOrderedChanges(toBuild other: Self) -> [ChangeStep<Element, Int>] {
        return notFullyOrderedChanges(toBuild: other, identifier: { $0 }, needsUpdate: !=)
    }
}

extension ChangeStep {
    /// Maps over steps item
    func map<T>(_ transform: (Item) throws -> T) rethrows -> ChangeStep<T, Index> {
        switch self {
        case let .insert(item, index):
            return try .insert(item: transform(item), at: index)
        case let .delete(item, index):
            return try .delete(item: transform(item), at: index)
        case let .update(item, index):
            return try .update(item: transform(item), at: index)
        case let .move(item, fromIndex, toIndex):
            return try .move(item: transform(item), from: fromIndex, to: toIndex)
        }
    }

    /// Maps over steps index
    func mapIndex<T>(_ transform: (Index) throws -> T) rethrows -> ChangeStep<Item, T> {
        switch self {
        case let .insert(item, index):
            return try .insert(item: item, at: transform(index))
        case let .delete(item, index):
            return try .delete(item: item, at: transform(index))
        case let .move(item, fromIndex, toIndex):
            return try .move(item: item, from: transform(fromIndex), to: transform(toIndex))
        case let .update(item, index):
            return try .update(item: item, at: transform(index))
        }
    }
}

public extension MutableCollection where Self: RangeReplaceableCollection {
    /// Applies given changes to a given array
    ///
    /// - Parameters:
    ///   - changes: Array of `ChangeStep`
    mutating func apply(_ changes: [ChangeStep<Element, Index>]) {
        let sortedChanges = changes.sortedForBatchUpdate()

        for change in sortedChanges {
            switch change {
            case let .insert(item, index): insert(item, at: index)
            case let .delete(_, index): remove(at: index)
            case let .update(item, index): self[index] = item
            case .move: break // no moves
            }
        }
    }
}

private extension Collection {
    /// Sorts a Collection of `ChangeStep`s to have deletes coming first
    func sortedForBatchUpdate<Item, Index>() -> [ChangeStep<Item, Index>] where Element == ChangeStep<Item, Index>, Index: Comparable {
        var insertions = [ChangeStep<Item, Index>]()
        var deletions = [ChangeStep<Item, Index>]()
        var updates = [ChangeStep<Item, Index>]()

        for change in self {
            switch change {
            case .insert:
                insertions.append(change)
            case .delete:
                deletions.append(change)
            case let .move(item, fromIndex, toIndex):
                deletions.append(.delete(item: item, at: fromIndex))
                insertions.append(.insert(item: item, at: toIndex))
            case .update:
                updates.append(change)

            }
        }
        deletions.sort { $0.index > $1.index }
        insertions.sort { $0.index < $1.index }

        // Deletes and Updates are processed before inserts in batch operations. This means the indexes for the deletions are processed relative to the indexes of the collection view’s state before the batch operation, and the indexes for the insertions are processed relative to the indexes of the state after all the deletions in the batch operation.
        let sortedChanges = updates + deletions + insertions
        return sortedChanges
    }
}

internal extension ChangeStep {
    var index: Index {
        switch self {
        case let .insert(_, index): return index
        case let .delete(_, index): return index
        case let .move(_, fromIndex, _): return fromIndex
        case let .update(_, index): return index
        }
    }
}

private enum Counter {
    case zero, one, many

    var incremented: Counter {
        if case .zero = self { return .one }
        return .many
    }
}

private final class Symbol {
    var oldCounter: Counter = .zero
    var newCounter: Counter = .zero
    var oldIndexes = [Int]()

    var occursInBoth: Bool {
        return oldCounter != .zero && newCounter != .zero
    }
}

private enum Entry {
    case symbol(Symbol)
    case index(Int)
}
