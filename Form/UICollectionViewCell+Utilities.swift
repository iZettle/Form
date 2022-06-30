//
//  UICollectionViewCell+Utilities.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-10-02.
//  Copyright © 2017 PayPal Inc. All rights reserved.
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
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to name of `Item`'s type.
    /// - Parameter contentViewAndConfigure: A closure when given a reuse identifier returns a tuple of a view and a configure closure.
    ///     The configure closure passes the item to be used to configure the cell.
    ///     The disposable returned from the configure closure will be disposed before reusage.
    /// - Returns: A cell with the view embedded in.
    /// - Note: See `Reusable` for more info about reconfigure.
    func dequeueCell<Item>(forItem item: Item, at indexPath: IndexPath, reuseIdentifier: String = String(describing: Item.self), contentViewAndConfigure: () -> (UIView, (Item) -> Disposable)) -> UICollectionViewCell {
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        let cell = dequeueCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        cell.setItem(item, contentViewAndConfigure: contentViewAndConfigure)
        return cell
    }

    /// Dequeues (reuses) or creates a new view and using the `item`'s conformance to `Reusable` to create and configure the view to embed in the returned cell.
    func dequeueCell<Item: Reusable>(forItem item: Item, at indexPath: IndexPath) -> UICollectionViewCell where Item.ReuseType: ViewRepresentable {
        return dequeueCell(forItem: item, at: indexPath, reuseIdentifier: item.reuseIdentifier, contentViewAndConfigure: {
            let (viewRepresentable, configure) = Item.makeAndConfigure()
            return (viewRepresentable.viewRepresentation, configure)
        })
    }
}

public extension UICollectionView {
    /// Dequeues (reuses) or creates a new supplementary view for `indexPath`.
    /// - Parameter kind: The kind for the supplementary view.
    /// - Parameter reuseIdentifier: The reuse identifier for the supplementary view, defaults to `#function`.
    func dequeueSupplementaryView(withKind kind: String, reuseIdentifier: String = #function, for indexPath: IndexPath) -> UICollectionReusableView {
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifier, for: indexPath)
    }

    /// Dequeues (reuses) or creates a new supplementary view for `indexPath`.
    /// - Parameter item: The item used to configure the supplementary view.
    /// - Parameter kind: The kind for the supplementary view, defaults to name of `Item`'s type.
    /// - Parameter reuseIdentifier: The reuse identifier for the supplementary view, defaults to name of `Item`'s type.
    /// - Parameter contentViewAndConfigure: A closure when given a reuse identifier returns a tuple of a view and a configure closure.
    ///     The configure closure passes the item to be used to configure the supplementary view.
    ///     The disposable returned from the configure closure will be disposed before reusage.
    /// - Returns: A supplementary view with the view embedded in.
    /// - Note: See `Reusable` for more info about reconfigure.
    func dequeueSupplementaryView<Item>(forItem item: Item, at indexPath: IndexPath, kind: String, reuseIdentifier: String = String(describing: Item.self), contentViewAndConfigure: () -> (UIView, (Item) -> Disposable)) -> UICollectionReusableView {
        register(UICollectionReusableView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)

        let supplementaryView = dequeueSupplementaryView(withKind: kind, reuseIdentifier: reuseIdentifier, for: indexPath)
        supplementaryView.setItem(item, contentViewAndConfigure: contentViewAndConfigure)
        return supplementaryView
    }

    /// Dequeues (reuses) or creates a new view and using the `item`'s conformance to `Reusable` to create and configure the view to embed in the returned cell.
    func dequeueSupplementaryView<Item: Reusable>(forItem item: Item, kind: String = String(describing: Item.self), at indexPath: IndexPath) -> UICollectionReusableView where Item.ReuseType: ViewRepresentable {
        return dequeueSupplementaryView(forItem: item, at: indexPath, kind: kind, reuseIdentifier: item.reuseIdentifier, contentViewAndConfigure: {
            let (viewRepresentable, configure) = Item.makeAndConfigure()
            return (viewRepresentable.viewRepresentation, configure)
        })
    }
}

extension UICollectionReusableView {
    func configure<Item>(_ item: Item) {
        guard let (configure, bag) = configureAndBag(Item.self) else { return }
        bag.dispose()
        bag += configure(item)
    }

    func releaseBag<Item>(forType: Item.Type) {
        guard let (_, bag) = configureAndBag(Item.self) else { return }
        bag.dispose()
    }
}

private extension UICollectionReusableView {
    func configureAndBag<Item>(_ type: Item.Type) -> ((Item) -> Disposable, DisposeBag)? {
        return associatedValue(forKey: &collectionConfigureKey)
    }

    func setConfigureAndBag<Item>(_ configureAndBag: ((Item) -> Disposable, DisposeBag)) {
        setAssociatedValue(configureAndBag, forKey: &collectionConfigureKey)
    }
}
private var collectionConfigureKey = false

private extension UICollectionReusableView {
    func setItem<Item>(_ item: Item, contentViewAndConfigure: () -> (UIView, (Item) -> Disposable)) {
        if let (configure, bag) = configureAndBag(Item.self) {
            bag.dispose() // Reuse
            bag += configure(item)
        } else {
            let (contentView, configure) = contentViewAndConfigure()
            embedView(contentView)
            let bag = DisposeBag()
            setConfigureAndBag((configure, bag))
            bag += configure(item)
        }
    }
}
