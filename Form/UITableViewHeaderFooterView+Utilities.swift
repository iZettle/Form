//
//  UITableViewHeaderFooterView+Utilities.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-02.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

public extension UITableViewHeaderFooterView {
    /// Create a new instance with an embedded `view`.
    convenience init(view: UIView, reuseIdentifier: String) {
        self.init(reuseIdentifier: reuseIdentifier)
        contentView.embedView(view)
    }

    /// Create a new instance with an embedded `view`.
    convenience init(view: UIView? = nil, style: DynamicHeaderFooterStyle, formStyle: DynamicFormStyle, reuseIdentifier: String) {
        let content = UIView()
        self.init(view: content, reuseIdentifier: reuseIdentifier)

        let background = UIView()
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(imageView)

        let backgroundLeft: NSLayoutConstraint = background.leftAnchor == imageView.leftAnchor
        let backgroundRight: NSLayoutConstraint = imageView.rightAnchor == background.rightAnchor

        let backConstraints: [NSLayoutConstraint] = [backgroundLeft,
                                                     backgroundRight,
                                                     background.topAnchor == imageView.topAnchor,
                                                     background.bottomAnchor == imageView.bottomAnchor]

        backConstraints.forEach { $0.priority = .required - 1 }
        activate(backConstraints)

        self.backgroundView = background

        let bag = self.associatedValue(forKey: &headerBagKey, initial: DisposeBag())

        // Getting signal from content instead of self to avoid retain cycle between self and bag
        bag += content.traitCollectionWithFallbackSignal.distinct().atOnce().onValue { traits in
            let style = style.style(from: traits)
            let formStyle = formStyle.style(from: traits)

            imageView.image = style.backgroundImage
            backgroundLeft.constant = formStyle.insets.left
            backgroundRight.constant = formStyle.insets.right
        }

        guard let view = view else {
            let height = content.heightAnchor >= 0
            height.priority = .required - 1
            activate(height)
            bag += content.traitCollectionWithFallbackSignal.distinct().atOnce().onValue { traits in
                let style = style.style(from: traits)
                height.constant = style.emptyHeight
            }
            return
        }

        let left: NSLayoutConstraint = view.leftAnchor == content.leftAnchor
        let right: NSLayoutConstraint = view.rightAnchor == content.rightAnchor
        let top: NSLayoutConstraint = view.topAnchor == content.topAnchor
        let bottom: NSLayoutConstraint = view.bottomAnchor == content.bottomAnchor

        view.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(view)

        let constraints = [left, right, top, bottom]
        constraints.forEach { $0.priority = .required - 1 }
        activate(constraints)

        // Getting signal from content instead of self to avoid retain cycle between self and bag
        bag += content.traitCollectionWithFallbackSignal.distinct().atOnce().onValue { traits in
            let style = style.style(from: traits)
            let formStyle = formStyle.style(from: traits)

            top.constant = style.insets.top
            bottom.constant = -style.insets.bottom
            left.constant = style.insets.left + formStyle.insets.left
            right.constant = -(style.insets.right + formStyle.insets.right)

            if let label = view as? UILabel {
                label.style = style.text
            }
        }
    }
}

public extension UITableView {
    /// Dequeues (reuses) or creates a new header footer view.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to `#function`.
    func dequeueHeaderFooterView(reuseIdentifier: String = #function) -> UITableViewHeaderFooterView {
        return dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) ?? UITableViewHeaderFooterView(reuseIdentifier: reuseIdentifier)
    }

    /// Dequeues (reuses) or creates a new styled header footer view with `view` embedded.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to `#function`.
    func dequeueHeaderFooterView(using view: UIView?, style: DynamicHeaderFooterStyle, formStyle: DynamicFormStyle, reuseIdentifier: String = #function) -> UITableViewHeaderFooterView {
        return dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) ?? UITableViewHeaderFooterView(view: view, style: style, formStyle: formStyle, reuseIdentifier: reuseIdentifier)
    }

    /// Dequeues (reuse) or creates a new header footer view and using the `viewAndConfigure` closure to create and configure configure the cell.
    /// - Parameter item: The item used to configure the cell.
    /// - Parameter reuseIdentifier: The reuse identifer for the cell, defaults to `#function`.
    /// - Parameter viewAndConfigure: Closure when given a reuse identifier returns a tuple of a View and a configure closure.
    ///     The configure closure passes the item to be used to configure the view and returns a `Disposable` the will be disposed on reuse.
    func dequeueHeaderFooterView<Item, View: UITableViewHeaderFooterView>(forItem item: Item, reuseIdentifier: String = #function, viewAndConfigure: (String) -> (View, (Item) -> Disposable)) -> View {
        let view: View
        let bag: DisposeBag
        let configure: (Item) -> Disposable
        if let reuseView = dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? View {
            view = reuseView
            (configure, bag) = view.associatedValue(forKey: &configureKey)!
            bag.dispose() // Reuse
       } else {
            (view, configure) = viewAndConfigure(reuseIdentifier)
            bag = DisposeBag()
            view.setAssociatedValue((configure, bag), forKey: &configureKey)
        }
        bag += configure(item)
        return view
    }

    /// Dequeues (reuses) or creates a new styled header footer view and using the `item`'s conformance to `Reusable` to create and configure the view to embed the header footer view.
    /// - Parameter reuseIdentifier: The reuse identifier for the cell, defaults to `#function`.
    func dequeueHeaderFooterView<Item: Reusable>(forItem item: Item, style: DynamicHeaderFooterStyle, formStyle: DynamicFormStyle, reuseIdentifier: String = #function) -> UITableViewHeaderFooterView where Item.ReuseType: ViewRepresentable {
        return dequeueHeaderFooterView(forItem: item, reuseIdentifier: reuseIdentifier, viewAndConfigure: { reuseIdentifier in
            let (viewRepresentable, configure) = Item.makeAndConfigure()
            return (UITableViewHeaderFooterView(view: viewRepresentable.viewRepresentation, style: style, formStyle: formStyle, reuseIdentifier: reuseIdentifier), configure)
        })
    }
}

extension String: Reusable {
    public static func makeAndConfigure() -> (make: UILabel, configure: (String) -> Disposable) {
        let label = UILabel()
        return (label, { title in
            label.value = title
            return NilDisposer()
        })
    }
}

public struct HeaderFooter: HeaderFooterReusable, Hashable {
    public var header: String
    public var footer: String

    public init(header: String, footer: String) {
        self.header = header
        self.footer = footer
    }
}

public struct DateHeader: Equatable {
    public let date: Date
    public let dateFormatter: DateFormatter

    public init(date: Date, dateFormatter: DateFormatter) {
        self.date = date
        self.dateFormatter = dateFormatter
    }
}

extension DateHeader: Reusable {
    public static func makeAndConfigure() -> (make: UILabel, configure: (DateHeader) -> Disposable) {
        let title = UILabel()
        return (title, { dateHeader in
            title.value = dateHeader.dateFormatter.string(from: dateHeader.date)
            return NilDisposer()
        })
    }
}

private var headerBagKey = false
private var configureKey = false
