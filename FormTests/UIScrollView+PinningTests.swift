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

        // no matter where the scrollview is positioned the pinning should be relative to its frame so adding some offset to test this assumption
        let scrollViewOffset: CGFloat = 50
        let (scrollView, container) = makeEmbeddedScrollView(
            size: CGSize(width: expectedHeight * 2, height: expectedHeight * 2),
            scrollViewOffset: scrollViewOffset
        )

        // When
        let disposable = scrollView.embedPinned(viewToEmbed, edge: edge, minHeight: pinningMinimumHeight)
        if let finalViewMinimumHeight = finalViewMinimumHeight {
            heightConstraint.constant = finalViewMinimumHeight
            viewToEmbed.setNeedsLayout()
            viewToEmbed.layoutIfNeeded()
        }

        scrollView.contentOffset = .zero
        container.setNeedsLayout()
        container.layoutIfNeeded()

        // Then
        let assertMessage = "pinning to `\(edge)`"
        XCTAssertEqual(viewToEmbed.frame.size.height, expectedHeight, assertMessage, file: file, line: line)

        if case .top = edge {
            XCTAssertEqual(viewToEmbed.frame.origin.y, 0, assertMessage, file: file, line: line)
            print(scrollView)
        } else if case .bottom = edge {
            let expectedOriginY = scrollView.frame.size.height - viewToEmbed.frame.size.height
            XCTAssertEqual(viewToEmbed.frame.origin.y, expectedOriginY, assertMessage, file: file, line: line)
        }

        disposable.dispose()
    }

    private func makeEmbeddedScrollView(size: CGSize, scrollViewOffset: CGFloat) -> (UIScrollView, UIView) {
        let scrollView = UIScrollView()
        let container = UIView(embeddedView: scrollView, edgeInsets: UIEdgeInsets(horizontalInset: 0, verticalInset: scrollViewOffset))
        container.frame = CGRect(origin: .zero, size: size)
        return (scrollView, container)
    }
}
