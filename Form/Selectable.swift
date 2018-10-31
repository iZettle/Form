//
//  Selectable.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-08-03.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Conforming types have a selected state that can be updated and observed.
public protocol Selectable {
    var isSelectedSignal: ReadWriteSignal<Bool> { get }
}

public extension Selectable {
    var isSelected: Bool {
        get { return isSelectedSignal.value }
        set { isSelectedSignal.value = newValue }
    }
}

extension UIControl: Selectable {
    public var isSelectedSignal: ReadWriteSignal<Bool> {
        return signal(for: \.isSelected).distinct()
    }
}

public extension Collection where Iterator.Element == ReadWriteSignal<Bool> {
    /// Ensures that only one `Selectable` in `self` is selected at one time.
    /// - Parameter alwaysOneSelected: If set to true, there is always one item selected (unless the collection is empty). Defaults to true.
    /// - Returns: A disposable that will stop maintaining selection when being disposed.
    func ensureSingleSelection(withAlwaysOneSelected alwaysOneSelected: Bool = true) -> Disposable {
        let bag = DisposeBag()
        func enforceOneSelection(fromSelection: ReadWriteSignal<Bool>?) {
            // The logical selection is the one that should be logically selected given the current state (either fromSelection is it just has been selected or the first selected item in the collection)
            let logicalSelection = fromSelection?.value == true ? fromSelection : self.first(where: { $0.value })
            // If no logical selection and need to always have one item selected we cancel the desection of fromSelection or select the first item
            let newSelection = logicalSelection ?? (alwaysOneSelected ? fromSelection ?? self.first : nil)

            newSelection?.value = true
            for isSelected in self {
                guard isSelected !== newSelection && isSelected.value else {
                    continue
                }
                isSelected.value = false
            }
        }
        for isSelected in self {
            bag += isSelected.distinct().onValue { _ in
                enforceOneSelection(fromSelection: isSelected)
            }
        }
        enforceOneSelection(fromSelection: nil)

        return bag
    }
}

public extension Collection where Iterator.Element: Selectable {
    /// Ensures that only one `Selectable` in `self` is selected at one time.
    /// - Parameter alwaysOneSelected: If set to true, there is always one item selected (unless the collection is empty). Defaults to true.
    /// - Returns: A disposable that will stop maintaining selection when being disposed.
    func ensureSingleSelection(withAlwaysOneSelected alwaysOneSelected: Bool = true) -> Disposable {
        return map { $0.isSelectedSignal }.ensureSingleSelection(withAlwaysOneSelected: alwaysOneSelected)
    }
}
