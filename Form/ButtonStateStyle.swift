//
//  ButtonStateStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-25.
//  Copyright © 2015 PayPal Inc. All rights reserved.
//

import UIKit

public struct ButtonStateStyle: Style {

    /// Generator closure for the background image.
    public var backgroundImageGenerator: (() -> UIImage?)?

    /// Static background image, used as a fallback for the background image generator.
    public var backgroundImageStatic: UIImage?

    /// Text style for the button state style.
    public var text: TextStyle

    /// Return the current background image for the state style.
    /// First it will check if there's a generator and use that, otherwise fall back on any set static background image.
    public var backgroundImage: UIImage? {
        return backgroundImageGenerator?() ?? backgroundImageStatic
    }

    /// - Parameters:
    ///   - backgroundImageGenerator: Background image generation closure. Will be called when the style is applied. Defaults to `nil`.
    ///   - backgroundImage: Static background image, used as a fallback for the background image generator. Defaults to `nil`.
    ///   - text: Text style for the button state style.
    public init(backgroundImageGenerator: (() -> UIImage?)? = nil, backgroundImage: UIImage? = nil, text: TextStyle) {
        self.backgroundImageStatic = backgroundImage
        self.backgroundImageGenerator = backgroundImageGenerator
        self.text = text
    }

}

public extension ButtonStateStyle {
    init(background: BackgroundStyle, text: TextStyle) {
        self.init(backgroundImageGenerator: { SegmentBackgroundStyle(style: background)?.image() }, text: text)
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

extension UIControl.State: Equatable {
    public static func == (lhs: UIControl.State, rhs: UIControl.State) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension UIControl.State: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

public typealias ButtonStatesStyle = [UIControl.State: ButtonStateStyle]

public extension UIBarMetrics {
    static let standardMetrics: [UIBarMetrics] = [.default, .compact, .defaultPrompt, .compactPrompt]
    static let standardMetricsNoPrompt: [UIBarMetrics] = [.default, .compact]
}

public extension UIControl.State {
    static let selectedAndHighlighted: UIControl.State = [.selected, .highlighted]
    static let standardStates: [UIControl.State] = [.normal, .highlighted, .disabled, .selected, selectedAndHighlighted]
    static let standardStatesNoSelected: [UIControl.State] = [.normal, .highlighted, .disabled]
}

public extension Dictionary where Key == UIControl.State {
    init(normal: Value? = nil, highlighted: Value? = nil, disabled: Value? = nil, selected: Value? = nil) {
        self.init()
        self[.normal] = normal
        self[.highlighted] = highlighted
        self[.disabled] = disabled
        self[.selected] = selected
        self[.selectedAndHighlighted] = highlighted ?? selected
    }
}

public extension Dictionary where Key == UIControl.State, Value: Style {
    mutating func allRestyled(_ styler: (inout Value) -> ()) {
        for state in UIControl.State.standardStates {
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
