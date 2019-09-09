//
//  BackgroundStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-10-25.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit

public struct BackgroundStyle: Style {
    public var color: UIColor
    public var border: BorderStyle

    public init(color: UIColor, border: BorderStyle) {
        self.color = color
        self.border = border
    }
}

public extension BackgroundStyle {
    static let none = BackgroundStyle(color: .clear, border: .none)
}

public extension UIImage {
    static func image(style: BackgroundStyle) -> UIImage? {
        return UIImage.image(
            border: style.border, bottomSeparator: .none,
            topSeparator: .none,
            background: style.color,
            position: .unique
        )
    }

    static func image(color: UIColor, border: BorderStyle) -> UIImage? {
        return UIImage.image(style: .init(color: color, border: border))
    }
}
