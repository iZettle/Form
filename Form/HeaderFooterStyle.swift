//
//  HeaderFooterStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-10-24.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

public struct HeaderFooterStyle: Style {
    public var text: TextStyle
    public var backgroundImage: UIImage?
    public var insets: UIEdgeInsets

    /// Fallback height used when there are no header or footer content.
    /// By using non-zero values, spacing can be added between sections.
    public var emptyHeight: CGFloat

    public init(text: TextStyle, backgroundImage: UIImage? = nil, insets: UIEdgeInsets = .zero, emptyHeight: CGFloat = 0) {
        self.text = text
        self.backgroundImage = backgroundImage
        self.insets = insets
        self.emptyHeight = emptyHeight
    }
}

public struct DynamicHeaderFooterStyle: DynamicStyle {
    public var styleGenerator: (UITraitCollection) -> HeaderFooterStyle
    public init(generateStyle : @escaping (UITraitCollection) -> HeaderFooterStyle) {
        self.styleGenerator = generateStyle
    }
}

public extension HeaderFooterStyle {
    static let none = HeaderFooterStyle(text: .default, emptyHeight: 0)
}
