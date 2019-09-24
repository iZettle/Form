//
//  ViewLayoutArea.swift
//  Form
//
//  Created by Nataliya Patsovska on 2018-01-29.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit

/// A rectangular area in the coordinate system of a view that can be translated to a UILayoutGuide and participate in Auto Layout.
public enum ViewLayoutArea {
    /// Use a layout guide set up to the edges of the view.
    case `default`

    /// Use the view's safeAreaGuide.
    case safeArea

    /// Use a custom guide.
    case custom(UILayoutGuide)
}

extension UIView {
    func layoutGuide(for layoutArea: ViewLayoutArea) -> UILayoutGuide {
        switch layoutArea {
        case .default:
            return defaultLayoutGuide
        case .safeArea:
            guard #available(iOS 11, *) else { return defaultLayoutGuide }
            return safeAreaLayoutGuide
        case .custom(let guide):
            return guide
        }
    }
}

private extension UIView {
    var defaultLayoutGuide: UILayoutGuide {
        return associatedValue(forKey: &viewDefaultLayoutGuideKey, initial: UILayoutGuide(self))
    }
}

private extension UILayoutGuide {
    /// Creates a UILayoutGuide instance that follows the anchors of the view
    convenience init(_ view: UIView) {
        self.init()
        view.addLayoutGuide(self)

        let constraints: [NSLayoutConstraint] = [
            view.leadingAnchor == self.leadingAnchor,
            view.trailingAnchor == self.trailingAnchor,
            view.leftAnchor == self.leftAnchor,
            view.rightAnchor == self.rightAnchor,
            view.topAnchor == self.topAnchor,
            view.bottomAnchor == self.bottomAnchor,
            view.widthAnchor == self.widthAnchor,
            view.heightAnchor == self.heightAnchor,
            view.centerXAnchor == self.centerXAnchor,
            view.centerYAnchor == self.centerYAnchor
        ]
        activate(constraints)
    }
}

private var viewDefaultLayoutGuideKey = false
