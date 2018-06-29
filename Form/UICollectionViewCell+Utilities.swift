//
//  UICollectionViewCell+Utilities.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-10-02.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UICollectionView {
    /// Dequeues (reuses) or creates a new cell for `indexPath`.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to `#function`.
    func dequeueCell(withReuseIdentifier reuseIdentifier: String = #function, for indexPath: IndexPath) -> UICollectionViewCell {
        return dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    }

    /// Dequeues (reuses) or creates a new cell for `indexPath`.
    /// - Parameter item: The item used to configure the cell.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to `#function`.
    /// - Parameter contentViewAndConfigure: A closure when given a reuse identifier returns a tuple of a view and a configure closure.
    ///     The configure closure passes the item to be used to configure the cell.
    ///     The disposable returned from the configure closure will be disposed before reusage.
    /// - Returns: A cell with the view embedded in.
    /// - Note: See `Reusable` for more info about reconfigure.
    func dequeueCell<Item>(forItem item: Item, at indexPath: IndexPath, contentViewAndConfigure: () -> (UIView, (Item) -> Disposable)) -> UICollectionViewCell {
        let reuseIdentifier = String(describing: Item.self)

        register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        let cell = dequeueCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let (configure, bag) = cell.configureAndBag(Item.self) {
            bag.dispose() // Reuse
            bag += configure(item)
            return cell
        } else {
            let (contentView, configure) = contentViewAndConfigure()
            cell.embedView(contentView)
            let bag = DisposeBag()
            cell.setConfigureAndBag((configure, bag))
            bag += configure(item)
            return cell
        }
    }

    /// Dequeues (reuses) or creates a new view and using the `item`'s conformance to `Reusable` to create and configure the view to embed in the returned cell.
    func dequeueCell<Item: Reusable>(forItem item: Item, at indexPath: IndexPath) -> UICollectionViewCell where Item.ReuseType: ViewRepresentable {
        return dequeueCell(forItem: item, at: indexPath, contentViewAndConfigure: {
            let (viewRepresentable, configure) = Item.makeAndConfigure()
            return (viewRepresentable.viewRepresentation, configure)
        })
    }

    /// Dequeues (reuses) or creates a new view and using the `item`'s conformance to `Reusable` to create and configure the view to embed in the returned supplementary view.
    func dequeueSupplentaryView<Item: Reusable>(at indexPath: IndexPath, for type: Item.Type) -> UICollectionReusableView where Item.ReuseType: ViewRepresentable {
        let reuseIdentifier = String(describing: type)
        let supplementaryView = dequeueReusableSupplementaryView(ofKind: reuseIdentifier, withReuseIdentifier: reuseIdentifier, for: indexPath)
        if supplementaryView.subviews.count == 0 {
            let view = type.makeAndConfigure().make.viewRepresentation
            supplementaryView.embedView(view)
        }
        return supplementaryView
    }
}

private extension UICollectionViewCell {
    func configureAndBag<Item>(_ type: Item.Type) -> ((Item) -> Disposable, DisposeBag)? {
        return associatedValue(forKey: &collectionConfigureKey)
    }

    func setConfigureAndBag<Item>(_ configureAndBag: ((Item) -> Disposable, DisposeBag)) {
        setAssociatedValue(configureAndBag, forKey: &collectionConfigureKey)
    }
}

private var collectionConfigureKey = false
