//
//  SelectViewTests.swift
//  Flow
//
//  Created by Emmanuel Garnier on 2017-07-20.
//  Copyright © 2017 iZettle. All rights reserved.
//

import XCTest
import Form
import Flow

class SelectViewTests: XCTestCase {
    func testMaximumOneSelected() {
        let ppties: [UIButton] = (0..<5).map { _ in UIButton() }

        let bag = DisposeBag()

        bag += ppties.ensureSingleSelection(withAlwaysOneSelected: false)

        ppties[2].isSelected = true
        ppties[3].isSelected = true

        XCTAssertEqual(ppties.map { $0.isSelected }, [false, false, false, true, false])
    }

    func testMaximumOneAtInitSelected() {
        let ppties: [UIButton] = (0..<5).map { _ in
            let button = UIButton()
            button.isSelected = true
            return button
        }

        let bag = DisposeBag()

        bag += ppties.ensureSingleSelection(withAlwaysOneSelected: false)

        XCTAssertEqual(ppties.map { $0.isSelected }, [true, false, false, false, false])
    }

    func testOneSelectedByDefault() {
        let ppties: [UIButton] = (0..<5).map { _ in UIButton() }

        let bag = DisposeBag()

        bag += ppties.ensureSingleSelection(withAlwaysOneSelected: true)

        XCTAssertEqual(ppties.map { $0.isSelected }, [true, false, false, false, false])
    }

    func testDeselectOfLastItemNotPermitted() {
        let ppties: [UIButton] = (0..<5).map { _ in UIButton() }

        let bag = DisposeBag()

        ppties[4].isSelected = true

        bag += ppties.ensureSingleSelection(withAlwaysOneSelected: true)

        ppties[4].isSelected = false
        XCTAssertEqual(ppties.map { $0.isSelected }, [false, false, false, false, true])
    }
}
