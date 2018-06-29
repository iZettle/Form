//
//  SelectViewTests.swift
//  Flow
//
//  Created by João D. Moreira on 2017-08-15.
//  Copyright © 2017 iZettle. All rights reserved.
//

import XCTest
import Form
import Flow

class HighlightedViewTests: XCTestCase {
    func testUILabelHighlighted() {
        let bag = DisposeBag()
        let label = UILabel()
        let highlightedExpectation = expectation(description: "UILabel highlighted KVO triggered")
        bag += label.isHighlightedSignal.onValue {_ in
            highlightedExpectation.fulfill()
        }
        label.isHighlighted = true
        waitForExpectations(timeout: 1) { _ in
            bag.dispose()
        }
    }

    func testUIImageViewHighlighted() {
        let bag = DisposeBag()
        let imgView = UIImageView()
        let highlightedExpectation = expectation(description: "UIImageView highlighted KVO triggered")
        bag += imgView.isHighlightedSignal.onValue {_ in
            highlightedExpectation.fulfill()
        }
        imgView.isHighlighted = true
        waitForExpectations(timeout: 1) { _ in
            bag.dispose()
        }
    }
}
