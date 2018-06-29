//
//  ButtonStateStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-25.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public struct ButtonStateStyle: Style {
    public var backgroundImage: UIImage?
    public var text: TextStyle

    public init(backgroundImage: UIImage? = nil, text: TextStyle) {
        self.backgroundImage = backgroundImage
        self.text = text
    }
}

public extension ButtonStateStyle {
    init(background: BackgroundStyle, text: TextStyle) {
        self.init(backgroundImage: UIImage(style: background), text: text)
    }

    init(color: UIColor, border: BorderStyle, text: TextStyle) {
        self.init(background: .init(color: color, border: border), text: text)
    }
}

public extension ButtonStateStyle {
    func alphaColored(_ alpha: CGFloat) -> ButtonStateStyle {
        return restyled { $0.text = $0.text.alphaColored(alpha) }
    }
}

extension UIControlState: Equatable {
    public static func ==(lhs: UIControlState, rhs: UIControlState) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension UIControlState: Hashable {
    public var hashValue: Int {
        return Int(rawValue)
    }
}

public typealias ButtonStatesStyle = [UIControlState: ButtonStateStyle]

public extension UIBarMetrics {
    static let standardMetrics: [UIBarMetrics] = [.default, .compact, .defaultPrompt, .compactPrompt]
    static let standardMetricsNoPrompt: [UIBarMetrics] = [.default, .compact]
}

public extension UIControlState {
    static let standardStates: [UIControlState] = [.normal, .highlighted, .disabled, .selected]
    static let standardStatesNoSelected: [UIControlState] = [.normal, .highlighted, .disabled]
}

public extension Dictionary where Key == UIControlState {
    init(normal: Value? = nil, highlighted: Value? = nil, disabled: Value? = nil, selected: Value? = nil) {
        self.init()
        self[.normal] = normal
        self[.highlighted] = highlighted
        self[.disabled] = disabled
        self[.selected] = selected
    }
}

public extension Dictionary where Key == UIControlState, Value: Style {
    mutating func allRestyled(_ styler: (inout Value) -> ()) {
        for state in UIControlState.standardStates {
            self[state] = self[state]?.restyled(styler)
        }
    }
}

public extension Dictionary where Key == UIBarMetrics {
    init(default: Value, compact: Value? = nil, defaultPrompt: Value? = nil, compactPrompt: Value? = nil) {
        self.init()
        self[.default] = `default`
        self[.compact] = compact
        self[.defaultPrompt] = defaultPrompt
        self[.compactPrompt] = compactPrompt
    }
}
