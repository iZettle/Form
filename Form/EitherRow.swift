//
//  EitherRow.swift
//  Form
//
//  Created by Emmanuel Garnier on 21/09/16.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Helper type to provide either a left or right reusable view.
@available(*, deprecated, message: "REMOVE ME Use `Either` type directly instead")
public struct EitherRow<Left: Reusable, Right: Reusable> where Left.ReuseType: ViewRepresentable, Right.ReuseType: ViewRepresentable {
    public let item: Either<Left, Right>

    public init(_ item: Either<Left, Right>) { self.item = item }
    public init(_ left: Left) { item = .left(left) }
    public init(_ right: Right) { item = .right(right) }
}

@available(*, deprecated, message: "REMOVE ME Use `Either` type directly instead")
extension EitherRow: Reusable {
    public static func makeAndReconfigure() -> (make: UIView, reconfigure: (EitherRow<Left, Right>?, EitherRow<Left, Right>) -> Disposable) {
        let row = UIStackView()
        let (leftRow, leftReconfigure) = Left.makeAndReconfigure()
        let (rightRow, rightReconfigure) = Right.makeAndReconfigure()

        func updateViewRepresentation(_ view: UIView) {
            row.orderedViews = [view]
        }

        func reconfigure(prev: EitherRow<Left, Right>?, item: EitherRow<Left, Right>) -> Disposable {
            switch (prev?.item, item.item) {
            case (let .some(.left(prev)), let .left(item)): return leftReconfigure(prev, item)
            case (let .some(.right(prev)), let .right(item)): return rightReconfigure(prev, item)
            case (_, let .left(item)):
                updateViewRepresentation(leftRow.viewRepresentation)
                return leftReconfigure(nil, item)
            case (_, let .right(item)):
                updateViewRepresentation(rightRow.viewRepresentation)
                return rightReconfigure(nil, item)
            }
        }

        return (row, reconfigure)
    }
}
