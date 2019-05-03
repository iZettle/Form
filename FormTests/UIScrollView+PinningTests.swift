//
//  Copyright © 2019 iZettle. All rights reserved.
//

import XCTest
import Form
import Flow

class UIScrollViewPinningTests: XCTestCase {
    func testPinningWithMinHeight_finalViewHeightHigherThanMinHeight() {
        verifyPinningViewToTopAndToBottom(initialViewMinimumHeight: 200,
                                          pinningMinimumHeight: 100,
                                          expectedHeight: 200)
    }

    func testPinningWithMinHeight_finalViewHeightEqualToMinHeight() {
        verifyPinningViewToTopAndToBottom(initialViewMinimumHeight: 200,
                                          pinningMinimumHeight: 400,
                                          expectedHeight: 400)
    }

    func testPinningWithMinHeight_finalViewHeightHigherThanMinHeight_afterHeighUpdate() {
        verifyPinningViewToTopAndToBottom(initialViewMinimumHeight: 0,
                                          finalViewMinimumHeight: 200,
                                          pinningMinimumHeight: 100,
                                          expectedHeight: 200)
    }

    func testPinningWithMinHeight_finalViewHeightEqualToMinHeight_afterHeighUpdate() {
        verifyPinningViewToTopAndToBottom(initialViewMinimumHeight: 1000,
                                          finalViewMinimumHeight: 200,
                                          pinningMinimumHeight: 400,
                                          expectedHeight: 400)
    }

    // MARK: - Helpers
    func verifyPinningViewToTopAndToBottom(initialViewMinimumHeight: CGFloat,
                                           finalViewMinimumHeight: CGFloat? = nil,
                                           pinningMinimumHeight: CGFloat,
                                           expectedHeight: CGFloat,
                                           file: StaticString = #file,
                                           line: UInt = #line) {
        for edge in UIScrollView.PinEdge.allCases {
            verifyViewPinning(to: edge,
                              initialViewMinimumHeight: initialViewMinimumHeight,
                              finalViewMinimumHeight: finalViewMinimumHeight,
                              pinningMinimumHeight: pinningMinimumHeight,
                              expectedHeight: expectedHeight,
                              file: file,
                              line: line)
        }
    }

    private func verifyViewPinning(to edge: UIScrollView.PinEdge,
                                   initialViewMinimumHeight: CGFloat,
                                   finalViewMinimumHeight: CGFloat? = nil,
                                   pinningMinimumHeight: CGFloat,
                                   expectedHeight: CGFloat,
                                   file: StaticString = #file,
                                   line: UInt = #line) {
        // Given
        let viewToEmbed = UIView()
        let heightConstraint: NSLayoutConstraint = viewToEmbed.heightAnchor >= initialViewMinimumHeight
        activate(heightConstraint)

        let (scrollView, _) = makeEmbeddedScrollView(size: CGSize(width: expectedHeight * 2, height: expectedHeight * 2))

        // When
        let disposable = scrollView.embedPinned(viewToEmbed, edge: edge, minHeight: pinningMinimumHeight)
        if let finalViewMinimumHeight = finalViewMinimumHeight {
            heightConstraint.constant = finalViewMinimumHeight
            viewToEmbed.setNeedsLayout()
            viewToEmbed.layoutIfNeeded()
        }

        // Then
        XCTAssertEqual(viewToEmbed.frame.size.height, expectedHeight, "pinning to `\(edge)`", file: file, line: line)
        disposable.dispose()
    }

    private func makeEmbeddedScrollView(size: CGSize) -> (UIScrollView, UIView) {
        let scrollView = UIScrollView()
        let container = UIView(embeddedView: scrollView)
        container.frame = CGRect(origin: .zero, size: size)
        return (scrollView, container)
    }
}
