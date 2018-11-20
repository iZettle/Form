//
//  MinimumSize.swift
//  FlowFramework
//
//  Created by Nataliya Patsovska on 2018-11-20.
//

import Foundation

public struct MinimumSize: Style {
    public var width: Dimension?
    public var height: Dimension?

    public init(width: Dimension? = nil, height: Dimension? = nil) {
        self.width = width
        self.height = height
    }
}

public extension MinimumSize {
    struct Dimension {
        let value: CGFloat
        let priority: UILayoutPriority

        public init(_ value: CGFloat, priority: UILayoutPriority = .required) {
            self.value = value
            self.priority = priority
        }
    }
}

public extension MinimumSize {
    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width.flatMap { Dimension($0) }
        self.height = height.flatMap { Dimension($0) }
    }
}

public extension MinimumSize {
    static let none = MinimumSize()
}
