//
//  UIImage+Styling.swift
//  Form
//
//  Created by Emmanuel Garnier on 2016-10-17.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit

public extension UIImage {
    @nonobjc static let chevron: UIImage = {
        let side: CGFloat = 5.25
        let line: CGFloat = 1.75

        UIGraphicsBeginImageContextWithOptions(CGSize(width: side + line*4, height: (side + line*2)*2), false, 0)
        let context = UIGraphicsGetCurrentContext()!

        let stroke = UIBezierPath()
        stroke.move(to: CGPoint(x: line*2, y: line*2))
        stroke.addLine(to: CGPoint(x: side+line*2, y: side+line*2))
        stroke.addLine(to: CGPoint(x: line*2, y: side*2+line*2))
        stroke.lineCapStyle = .square
        stroke.lineWidth = line
        UIColor(white: 0.78, alpha: 1).setStroke()
        stroke.stroke()

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return image
    }()
}

enum CellPosition {
    case top
    case middle
    case bottom
    case unique
}

extension UIImage {
    convenience init?(border: BorderStyle,
                      bottomSeparator: InsettedStyle<SeparatorStyle>,
                      topSeparator: InsettedStyle<SeparatorStyle>,
                      background: UIColor,
                      position: CellPosition) {
        if border.color == .clear, background == .clear, bottomSeparator.style.color == .clear, topSeparator.style.color == .clear {
            return nil
        }

        let cornerRadius: CGFloat = border.cornerRadius
        let borderWidth = border.width
        let bottomSeparatorHeight: CGFloat = bottomSeparator.style.width
        let bottomSeparatorInsets = bottomSeparator.insets
        let topSeparatorHeight: CGFloat = topSeparator.style.width
        let topSeparatorInsets = topSeparator.insets
        // Rounding up the borderWidth and the separatorHeight to avoid visual artifacts ont the simulator (only used for capInsets and defining the image size)
        let ceiledBorderWidths = UIEdgeInsets(top: border.borderEdges.contains(.top) ? ceil(borderWidth) : 0,
                                             left: border.borderEdges.contains(.left) ? ceil(borderWidth) : 0,
                                             bottom: border.borderEdges.contains(.bottom) ? ceil(borderWidth) : 0,
                                             right: border.borderEdges.contains(.right) ? ceil(borderWidth) : 0)
        let ceiledSeparatorHeight = ceil(bottomSeparatorHeight)
        let ceiledTopSeparatorHeight = ceil(topSeparatorHeight)

        // Computing the smallest rect possible to draw this image - note that it should be slightly bigger than the border widths so that it draws a stretchable non-solid area too
        let rectWidth = cornerRadius * 2 + ceiledBorderWidths.left + 2 * .thinestLineWidth + ceiledBorderWidths.right + max(bottomSeparatorInsets.left, topSeparatorInsets.left) + max(bottomSeparatorInsets.right, topSeparatorInsets.right)
        let rectHeight = cornerRadius * 2 + ceiledBorderWidths.top + 2 * .thinestLineWidth + ceiledBorderWidths.bottom + ceiledSeparatorHeight + ceiledTopSeparatorHeight
        let rect = CGRect(x: 0, y: 0, width: max(1, rectWidth), height: max(1, rectHeight))

        let isOpaque: Bool
        switch (position, cornerRadius != 0, background.isOpaque) {
        case (_, false, true), (.middle, _, true):
            isOpaque = true
        default:
            isOpaque = false
        }

        UIGraphicsBeginImageContextWithOptions(rect.size, isOpaque, 0)
        let context = UIGraphicsGetCurrentContext()!

        border.color.setStroke()
        background.setFill()

        context.setLineWidth(borderWidth)

        let strokePath = CGMutablePath()
        let backgroundPath = CGMutablePath()

        var addSeparator: Bool = false
        var addTopSeparator: Bool = false
        let capInsets: UIEdgeInsets

        // Strokes are drawn on each side of the line, because we want the stroke inside the bounds, we add an inset of half the width of the line
        let halfBorderWidth = borderWidth / 2
        var borderRectInsets = UIEdgeInsets(top: border.borderEdges.contains(.top) ? halfBorderWidth : 0,
                                            left: border.borderEdges.contains(.left) ? halfBorderWidth : 0,
                                            bottom: border.borderEdges.contains(.bottom) ? halfBorderWidth : 0,
                                            right: border.borderEdges.contains(.right) ? halfBorderWidth : 0)

        switch position {
        case .unique:
            let bounds = rect.inset(by: borderRectInsets)
            strokePath.addRoundedRect(in: bounds, topCornerRadius: cornerRadius, bottomCornerRadius: cornerRadius, edges: border.borderEdges)
            backgroundPath.addRoundedRect(in: rect, topCornerRadius: cornerRadius, bottomCornerRadius: cornerRadius)
            capInsets = UIEdgeInsets(top: cornerRadius + ceiledBorderWidths.top,
                                     left: max(cornerRadius + ceiledBorderWidths.left, bottomSeparatorInsets.left, topSeparatorInsets.left),
                                     bottom: cornerRadius + ceiledBorderWidths.bottom,
                                     right: max(cornerRadius + ceiledBorderWidths.right, bottomSeparatorInsets.right, topSeparatorInsets.right))
        case .top:
            borderRectInsets.bottom = 0
            let bounds = rect.inset(by: borderRectInsets)
            strokePath.addRoundedRect(in: bounds, topCornerRadius: cornerRadius, bottomCornerRadius: 0, edges: border.borderEdges.intersection([.top, .left, .right]))
            backgroundPath.addRoundedRect(in: rect, topCornerRadius: cornerRadius, bottomCornerRadius: 0)
            addSeparator = true
            capInsets = UIEdgeInsets(top: cornerRadius + ceiledBorderWidths.top,
                                     left: max(cornerRadius + ceiledBorderWidths.left, bottomSeparatorInsets.left, topSeparatorInsets.left),
                                     bottom: ceiledSeparatorHeight,
                                     right: max(cornerRadius + ceiledBorderWidths.right, bottomSeparatorInsets.right, topSeparatorInsets.right))
        case .bottom:
            borderRectInsets.top = 0
            let bounds = rect.inset(by: borderRectInsets)
            strokePath.addRoundedRect(in: bounds, topCornerRadius: 0, bottomCornerRadius: cornerRadius, edges: border.borderEdges.intersection([.bottom, .left, .right]))
            backgroundPath.addRoundedRect(in: rect, topCornerRadius: 0, bottomCornerRadius: cornerRadius)
            addTopSeparator = true
            capInsets = UIEdgeInsets(top: ceiledTopSeparatorHeight,
                                     left: max(cornerRadius + ceiledBorderWidths.left, bottomSeparatorInsets.left, topSeparatorInsets.left),
                                     bottom: cornerRadius + ceiledBorderWidths.bottom,
                                     right: max(cornerRadius + ceiledBorderWidths.right, bottomSeparatorInsets.right, topSeparatorInsets.right))
        case .middle:
            borderRectInsets.top = 0
            borderRectInsets.bottom = 0
            let bounds = rect.inset(by: borderRectInsets)
            strokePath.addRoundedRect(in: bounds, topCornerRadius: 0, bottomCornerRadius: 0, edges: border.borderEdges.intersection([.left, .right]))
            backgroundPath.addRoundedRect(in: rect, topCornerRadius: 0, bottomCornerRadius: 0, edges: .all)
            addSeparator = true
            addTopSeparator = true
            capInsets = UIEdgeInsets(top: ceiledTopSeparatorHeight,
                                     left: max(ceiledBorderWidths.left, bottomSeparatorInsets.left, topSeparatorInsets.left),
                                     bottom: ceiledSeparatorHeight,
                                     right: max(ceiledBorderWidths.right, bottomSeparatorInsets.right, topSeparatorInsets.right))
        }

        UIBezierPath(cgPath: backgroundPath).fill()
        let stroke = UIBezierPath(cgPath: strokePath)
        stroke.lineCapStyle = .square
        stroke.lineWidth = borderWidth
        stroke.stroke()

        if addSeparator {
            bottomSeparator.style.color.setFill()
            let separatorRect = CGRect(x: rect.minX + bottomSeparatorInsets.left,
                                       y: rect.maxY - bottomSeparatorHeight,
                                       width: rect.size.width - bottomSeparatorInsets.left - bottomSeparatorInsets.right,
                                       height: bottomSeparatorHeight)
            context.fill(separatorRect)

        }

        if addTopSeparator {
            topSeparator.style.color.setFill()
            let separatorRect = CGRect(x: rect.minX + topSeparatorInsets.left,
                                       y: 0,
                                       width: rect.size.width - topSeparatorInsets.left - topSeparatorInsets.right,
                                       height: topSeparatorHeight)
            context.fill(separatorRect)

        }

        let image = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        self.init(__image: image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch))
    }
}

extension UIImage {
    convenience init?(style: SectionBackgroundStyle, position: CellPosition = .unique) {
        self.init(border: style.border,
                  bottomSeparator: style.bottomSeparator,
                  topSeparator: style.topSeparator,
                  background: style.color,
                  position: position)
    }
}

extension CellPosition {
    init(isFirst: Bool, isLast: Bool) {
        switch (isFirst, isLast) {
        case (true, true):
            self = .unique
        case (true, false):
            self = .top
        case (false, true):
            self = .bottom
        case (false, false):
            self = .middle
        }
    }
}

private extension CGMutablePath {
    func addRoundedRect(in rect: CGRect, topCornerRadius: CGFloat = 0, bottomCornerRadius: CGFloat = 0, edges: UIRectEdge = .all) {
        // Top
        if edges.contains(.top) {
            move(to: CGPoint(x: rect.minX, y: rect.minY + topCornerRadius))
            addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY), radius: topCornerRadius)
            addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + topCornerRadius), radius: topCornerRadius)
        } else {
            move(to: CGPoint(x: rect.maxX, y: rect.minY + topCornerRadius))
        }

        // Right
        if edges.contains(.right) {
            addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomCornerRadius))
        } else {
            move(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomCornerRadius))
        }

        // Bottom
        if edges.contains(.bottom) {
            addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - bottomCornerRadius, y: rect.maxY), radius: bottomCornerRadius)
            addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - bottomCornerRadius), radius: bottomCornerRadius)
        } else {
            move(to: CGPoint(x: rect.minX, y: rect.maxY - bottomCornerRadius))
        }

        // Left
        if edges.contains(.left) {
            addLine(to: CGPoint(x: rect.minX, y: rect.minY + topCornerRadius))
        }
    }
}

private extension UIColor {
    var isOpaque: Bool {
        return cgColor.alpha == 1.0
    }
}
