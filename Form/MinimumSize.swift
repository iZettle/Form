//
//  MinimumSize.swift
//  FlowFramework
//
//  Created by Nataliya Patsovska on 2018-11-20.
//

import UIKit

public struct MinimumSize: Style {
    public var width: CGFloat?
    public var height: CGFloat?
    public var priority: UILayoutPriority

    public init(width: CGFloat? = nil, height: CGFloat? = nil, priority: UILayoutPriority = .defaultHigh) {
        self.width = width
        self.height = height
        self.priority = priority
    }
}

public extension MinimumSize {
    static let none = MinimumSize()
}
