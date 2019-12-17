//
//  UILabel+ScalingTests.swift
//  FormTests
//
//  Created by Nataliya Patsovska on 2019-12-13.
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Form

@available(iOS 10.0, *)
class UILabelScalingTests: XCTestCase {

    func testInitialScaling_plainTextStyle() {
        func makeLabel() -> UILabel {
            let style = TextStyle.plain.restyled { $0.adjustsFontForContentSizeCategory = true }
            return UILabel(value: "Test", style: style)
        }

        let regularSize = labelPointSizeInScalingWindow(makeLabel(), windowSizeCategory: .large)
        let largerSize = labelPointSizeInScalingWindow(makeLabel(), windowSizeCategory: .extraExtraLarge)
        let smallerSize = labelPointSizeInScalingWindow(makeLabel(), windowSizeCategory: .extraSmall)

        XCTAssertGreaterThan(largerSize, regularSize)
        XCTAssertLessThan(smallerSize, regularSize)
    }

    func testScalingWhenSwitchingSizeCategory_plainTextStyle() {
        let style = TextStyle.plain.restyled { $0.adjustsFontForContentSizeCategory = true }
        let label = UILabel(value: "Test", style: style)

        let regularSize = labelPointSizeInScalingWindow(label, windowSizeCategory: .large)
        let largerSize = labelPointSizeInScalingWindow(label, windowSizeCategory: .extraExtraLarge)
        let smallerSize = labelPointSizeInScalingWindow(label, windowSizeCategory: .extraSmall)

        XCTAssertGreaterThan(largerSize, regularSize)
        XCTAssertLessThan(smallerSize, regularSize)
    }

    func testInitialScaling_customAttributesTextStyle() {
        func makeLabel() -> UILabel {
            let style = TextStyle.withCustomAttributes.restyled { $0.adjustsFontForContentSizeCategory = true }
            return UILabel(value: "Test", style: style)
        }

        let regularSize = labelPointSizeInScalingWindow(makeLabel(), windowSizeCategory: .large)
        let largerSize = labelPointSizeInScalingWindow(makeLabel(), windowSizeCategory: .extraExtraLarge)
        let smallerSize = labelPointSizeInScalingWindow(makeLabel(), windowSizeCategory: .extraSmall)

        XCTAssertGreaterThan(largerSize, regularSize)
        XCTAssertLessThan(smallerSize, regularSize)
    }

    func testScalingWhenSwitchingSizeCategory_customAttributesTextStyle() {
        let style = TextStyle.withCustomAttributes.restyled { $0.adjustsFontForContentSizeCategory = true }
        let label = UILabel(value: "Test", style: style)

        let regularSize = labelPointSizeInScalingWindow(label, windowSizeCategory: .large)
        let largerSize = labelPointSizeInScalingWindow(label, windowSizeCategory: .extraExtraLarge)
        let smallerSize = labelPointSizeInScalingWindow(label, windowSizeCategory: .extraSmall)

        XCTAssertGreaterThan(largerSize, regularSize)
        XCTAssertLessThan(smallerSize, regularSize)
    }

    // MARK: - Helpers

    func labelPointSizeInScalingWindow(_ label: UILabel, windowSizeCategory: UIContentSizeCategory) -> CGFloat {
        let window = CustomScalingWindow(sizeCategory: windowSizeCategory)
        window.addSubview(label)
        label.frame = window.bounds
        let pointSize = label.font.pointSize
        label.removeFromSuperview()
        return pointSize
    }

    private class CustomScalingWindow: UIWindow {
        let sizeCategory: UIContentSizeCategory
        init(sizeCategory: UIContentSizeCategory) {
            self.sizeCategory = sizeCategory
            super.init(frame: UIScreen.main.bounds)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var traitCollection: UITraitCollection {
            return UITraitCollection(preferredContentSizeCategory: sizeCategory)
        }
    }
}
