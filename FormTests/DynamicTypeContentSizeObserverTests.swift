//
//  DynamicTypeContentSizeObserverTests.swift
//  FormTests
//
//  Created by Nataliya Patsovska on 2019-05-08.
//  Copyright © 2019 iZettle. All rights reserved.
//

import Flow
@testable import Form
import XCTest

class ContentSizeObserverTests: XCTestCase {
    let sizeCategory = UIContentSizeCategory.small
    let notificationName = Notification.Name("Test")
    let key = UUID().uuidString
    var observer: DynamicTypeContentSizeObserver!

    override func setUp() {
        super.setUp()
        observer = DynamicTypeContentSizeObserver(
            getCurrentrPeferredContentSizeCategory: { [unowned self] in self.sizeCategory },
            observedNotification: notificationName,
            userInfoKey: key
        )
    }

    func testCurentValue() {
        XCTAssertEqual(observer.contentSizeCategory.value, sizeCategory)
    }

    func testUpdatedValue() {
        // given
        let updatedCategory = UIContentSizeCategory.extraLarge
        let sizeCategoryUpdate = expectation(description: "size category updated")
        let disposable = observer.contentSizeCategory.onValue { sizeCategory in
            XCTAssertEqual(sizeCategory, updatedCategory)
            sizeCategoryUpdate.fulfill()
        }

        // when
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: [key: updatedCategory])

        // then
        self.wait(for: [sizeCategoryUpdate], timeout: 0.1)
        disposable.dispose()
    }
}
