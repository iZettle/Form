//
//  FormStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-10-22.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public struct FormStyle: Style {
    public var insets: UIEdgeInsets

    public init(insets: UIEdgeInsets) {
        self.insets = insets
    }
}

public struct DynamicFormStyle: DynamicStyle {
    public var styleGenerator: (UITraitCollection) -> FormStyle
    public init(generateStyle : @escaping (UITraitCollection) -> FormStyle) {
        self.styleGenerator = generateStyle
    }
}

public extension DynamicFormStyle {
    static let systemGrouped = DynamicFormStyle { Style(traits: $0, isGrouped: true) }
    static let systemPlain = DynamicFormStyle { Style(traits: $0, isGrouped: false) }

    static var defaultGrouped: DynamicFormStyle { return DefaultStyling.current.formGrouped }
    static var defaultPlain: DynamicFormStyle { return DefaultStyling.current.formPlain }

    static var `default`: DynamicFormStyle { return defaultGrouped }
}

public extension DynamicFormStyle {
    /// Returns a restyled instance with insets.top = 0
    var openedTop: DynamicFormStyle {
        return restyled { $0.insets.top = 0 }
    }

    /// Returns a restyled instance with insets.bottom = 0
    var openedBottom: DynamicFormStyle {
        return restyled { $0.insets.bottom = 0 }
    }
}

private extension FormStyle {
    init(traits: UITraitCollection, isGrouped: Bool) {
        if isGrouped {
            switch traits.horizontalSizeClass {
            case .regular:
                insets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            default:
                // traits.displayScale used to hide board at left and right
                insets = UIEdgeInsets(top: 20, left: -traits.displayScale, bottom: 20, right: -traits.displayScale)
            }
        } else {
            insets = .zero
        }
    }
}
