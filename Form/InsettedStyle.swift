//
//  InsettedStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-20.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

/// A composition of a style and insets.
public struct InsettedStyle<Style: Form.Style> {
    public var style: Style
    public var insets: UIEdgeInsets

    public init(style: Style, insets: UIEdgeInsets) {
        self.style = style
        self.insets = insets
    }
}
