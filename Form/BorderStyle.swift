//
//  BorderStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-20.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public struct BorderStyle: Style {
    public var width: CGFloat
    public var color: UIColor
    public var cornerRadius: CGFloat
    public var borderEdges: UIRectEdge

    public init(width: CGFloat = 0, color: UIColor = .clear, cornerRadius: CGFloat = 0, borderEdges: UIRectEdge = .all) {
        self.width = width
        self.color = color
        self.cornerRadius = cornerRadius
        self.borderEdges = borderEdges
    }
}

public extension BorderStyle {
    static let none = BorderStyle(width: 0, color: .clear, cornerRadius: 0)
}
