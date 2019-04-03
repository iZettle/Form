//
//  UISegmentedControl+Styling.swift
//  Form
//
//  Created by Linnea Rönnqvist on 29/07/16.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

public struct SegmentedControlStyle {
    public var states: [UIBarMetrics: ButtonStatesStyle]
    public var tintColor: UIColor?

    /// [metric: [left: [right: image]]], see `UISegmentedControl.setDividerImage()``
    public typealias DividerImages = [UIBarMetrics: [UIControl.State: [UIControl.State: UIImage]]]
    public var dividerImages: DividerImages

    public init(states: [UIBarMetrics: ButtonStatesStyle], dividerImages: DividerImages = [:], tintColor: UIColor? = nil) {
        self.states = states
        self.tintColor = tintColor
        self.dividerImages = dividerImages
    }
}

public extension SegmentedControlStyle {
    init(normal: ButtonStateStyle? = nil, highlighted: ButtonStateStyle? = nil, disabled: ButtonStateStyle? = nil, selected: ButtonStateStyle? = nil, dividerImage: UIImage? = nil, tintColor: UIColor? = nil) {
        let states = ButtonStatesStyle(normal: normal, highlighted: highlighted, disabled: disabled, selected: selected)
        let dividerImages: DividerImages = dividerImage.map { [.default: [.normal: [.normal: $0]]] } ?? [:]
        self.init(states: .init(default: states), dividerImages: dividerImages, tintColor: tintColor)
    }
}

public extension SegmentedControlStyle {
    static let system = SegmentedControlStyle(states: [:])
    static var `default`: SegmentedControlStyle { return DefaultStyling.current.segmentedControl }
}

public extension UISegmentedControl {
    convenience init<T>(segments: [T], index: Int? = nil, style: SegmentedControlStyle = .default) {
        self.init(items: Optional(segments))
        if let index = index {
            providedSignal.value = index
        }
        applyStyle(style)
    }

    convenience init(titles: [DisplayableString], index: Int? = nil, style: SegmentedControlStyle = .default) {
        self.init(segments: titles.map { $0.displayValue }, index: index, style: style)
    }

    func applyStyle(_ style: SegmentedControlStyle) {
        tintColor = style.tintColor

        for state in UIControl.State.standardStates {
            let attributes = style.states[.default]?[state]?.text.attributes
            setTitleTextAttributes(attributes, for: state)

            for metric in UIBarMetrics.standardMetricsNoPrompt {
                setBackgroundImage(style.states[metric]?[state]?.backgroundImage, for: state, barMetrics: metric)

                let left = state
                for right in UIControl.State.standardStates {
                    setDividerImage(style.dividerImages[metric]?[left]?[right], forLeftSegmentState: left, rightSegmentState: right, barMetrics: metric)
                }
            }
        }
    }
}
