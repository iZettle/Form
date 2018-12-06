//
//  UtilitiesTests.swift
//  FormTests
//
//  Created by Carl Ekman on 2018-12-06.
//  Copyright © 2018 iZettle. All rights reserved.
//

import XCTest
import Form

class StackViewTests: XCTestCase {

    func testHelperFunction() {
        let empty = UIStackView(arrangedSubviews: [])
        let single = UIStackView(arrangedSubviews: [UIView(tag: 0)])
        let stack = UIStackView(arrangedSubviews: [UIView(tag: 0), UIView(tag: 1), UIView(tag: 2)])
        let wrong = UIStackView(arrangedSubviews: [UIView(tag: 0), UIView(tag: 2), UIView(tag: 1)])

        XCTAssertFalse(empty.subviewsHaveTagsEqualToIndex)
        XCTAssertTrue(single.subviewsHaveTagsEqualToIndex)
        XCTAssertTrue(stack.subviewsHaveTagsEqualToIndex)
        XCTAssertFalse(wrong.subviewsHaveTagsEqualToIndex)
    }

    func testCompoundAssignments() {
        var stack = UIStackView(arrangedSubviews: [UIView(tag: 0), UIView(tag: 1), UIView(tag: 2)])
        stack += [UIView(tag: 3), UIView(tag: 4)]
        stack += UIView(tag: 5)

        XCTAssertTrue(stack.subviewsHaveTagsEqualToIndex)
    }

    func testCompoundAssignmentsFromEmpty() {
        var stack = UIStackView(arrangedSubviews: [])
        stack += UIView(tag: 0)
        stack += [UIView(tag: 1), UIView(tag: 2)]
        stack += UIView(tag: 3)

        XCTAssertTrue(stack.subviewsHaveTagsEqualToIndex)
    }
}

fileprivate extension UIStackView {
    var subviewsHaveTagsEqualToIndex: Bool {
        guard arrangedSubviews.count > 0 else { return false }

        return arrangedSubviews.enumerated().reduce(true) { (last, this) in
            let (index, view) = this
            return last && (view.tag == index) }
    }
}

fileprivate extension UIView {
    convenience init(tag: Int) {
        self.init(frame: .zero)
        self.tag = tag
    }
}
