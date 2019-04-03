//
//  BarButtonStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-25.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public struct BarButtonStyle: Style {
    public var states: [UIBarMetrics: ButtonStatesStyle]

    public init(states: [UIBarMetrics: ButtonStatesStyle]) {
        self.states = states
    }
}

public extension BarButtonStyle {
    static let system = BarButtonStyle(text: ButtonStyle.system.states[.normal]?.text.resized(to: 17) ?? TextStyle(font: .systemFont(ofSize: 17), color: .black, alignment: .center))
    static var `default`: BarButtonStyle { return DefaultStyling.current.barButton }
}

public extension BarButtonStyle {
    init(default: ButtonStatesStyle, compact: ButtonStatesStyle? = nil, defaultPrompt: ButtonStatesStyle? = nil, compactPrompt: ButtonStatesStyle? = nil) {
        self.init(states: .init(default: `default`, compact: compact, defaultPrompt: defaultPrompt, compactPrompt: compactPrompt))
    }

    init(states: ButtonStatesStyle) {
        self.init(default: states, compact: states, defaultPrompt: states, compactPrompt: states)
    }

    init(normal: ButtonStateStyle, highlighted: ButtonStateStyle, disabled: ButtonStateStyle, selected: ButtonStateStyle) {
        self.init(states: ButtonStatesStyle(normal: normal, highlighted: highlighted, disabled: disabled, selected: selected))
    }

    init(text: TextStyle) {
        let stateStyle = ButtonStateStyle(text: text)
        self.init(normal: stateStyle,
                  highlighted: stateStyle.alphaColored(0.5),
                  disabled: stateStyle.alphaColored(0.3),
                  selected: stateStyle.alphaColored(0.5))
    }
}

public extension UIBarButtonItem {
    convenience init(system systemItem: UIBarButtonItem.SystemItem) {
        self.init(barButtonSystemItem: systemItem, target: nil, action: #selector(NSObject.description))
    }

    convenience init(title: DisplayableString, style: BarButtonStyle = .default) {
        self.init()
        setTitle(title)
        setStyle(style)
    }

    convenience init(title: DisplayableString, style textStyle: TextStyle) {
        self.init(title: title, style: BarButtonStyle(text: textStyle) )
    }
}

public extension UIBarButtonItem {
    var style: BarButtonStyle {
        get {
            return associatedValue(forKey: &styleKey, initial: BarButtonStyle(text: convertFromOptionalNSAttributedStringKeyDictionary(titleTextAttributes(for: .normal)).map { TextStyle(attributes: $0) } ?? .default))
        }
        set {
            setStyle(newValue)
        }
    }

    func setTitle(_ title: DisplayableString, for state: UIControl.State = .normal) {
        self.title = title.displayValue
        accessibilityIdentifier = title.accessibilityIdentifier
        accessibilityLabel = title.displayValue
        setStyle(style)
    }
}

public extension UIBarButtonItem {
    static var spacer: UIBarButtonItem { return UIBarButtonItem(system: .flexibleSpace) }

    static func spacer(width: CGFloat) -> UIBarButtonItem {
        let item = UIBarButtonItem(customView: UIView(width: width)) // not using .fixedSpace since the compression resistence is too low
        return item
    }
}

private extension UIBarButtonItem {
    func setStyle(_ style: BarButtonStyle) {
        setAssociatedValue(style, forKey: &styleKey)
        for state in UIControl.State.standardStatesNoSelected {
            setTitleTextAttributes(style.states[.default]?[state]?.text.attributes, for: state)
            for metric in UIBarMetrics.standardMetricsNoPrompt {
                setBackgroundImage(style.states[metric]?[state]?.backgroundImage, for: state, barMetrics: metric)
            }
        }
    }
}

private var styleKey = 0

// Helper function inserted by Swift 4.2 migrator.
private func convertFromOptionalNSAttributedStringKeyDictionary(_ input: [NSAttributedString.Key: Any]?) -> [String: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
