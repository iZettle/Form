//
//  ViewRepresentable.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-09-27.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Conforming types can be represented as a view.
public protocol ViewRepresentable {
    var viewRepresentation: UIView { get }
}

extension UIView: ViewRepresentable {
    public var viewRepresentation: UIView { return self }
}

public extension Sequence where Iterator.Element == ViewRepresentable {
    var views: [UIView] { return map { $0.viewRepresentation } }
}
