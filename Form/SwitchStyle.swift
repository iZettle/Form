//
//  SwitchStyle.swift
//  Form
//
//  Created by Emmanuel Garnier on 2017-03-13.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit

public struct SwitchStyle: Style {
    public var onTintColor: UIColor?
    public var thumbTintColor: UIColor?
    public var onImage: UIImage?
    public var offImage: UIImage?

    public init(onTintColor: UIColor?, thumbTintColor: UIColor? = nil, onImage: UIImage? = nil, offImage: UIImage? = nil) {
        self.onTintColor = onTintColor
        self.thumbTintColor = thumbTintColor
        self.onImage = onImage
        self.offImage = offImage
    }
}

public extension SwitchStyle {
    static let system = SwitchStyle(switch: UISwitch())
    static var `default`: SwitchStyle { return DefaultStyling.current.switch }
}

public extension UISwitch {
    convenience init(value: Bool, style: SwitchStyle = .default, accessibilityIdentifier: String? = nil) {
        self.init()
        providedSignal.value = value
        self.accessibilityIdentifier = accessibilityIdentifier

        applyStyle(style)
    }
}

public extension UISwitch {
    var style: SwitchStyle {
        get {
            return associatedValue(forKey: &styleKey, initial: SwitchStyle(switch: self))
        }
        set {
            applyStyle(newValue)
        }
    }
}

private extension UISwitch {
    func applyStyle(_ style: SwitchStyle) {
        onTintColor = style.onTintColor
        thumbTintColor = style.thumbTintColor
        onImage = style.onImage
        offImage = style.offImage

        setAssociatedValue(style, forKey: &styleKey)
    }
}

private extension SwitchStyle {
    init(switch aSwitch: UISwitch) {
        self.onTintColor = aSwitch.onTintColor
        self.thumbTintColor = aSwitch.thumbTintColor
        self.onImage = aSwitch.onImage
        self.offImage = aSwitch.offImage
    }
}

private var styleKey = 0
