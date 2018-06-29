//
//  TitleSubtitleStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2018-05-17.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit

public struct TitleSubtitleStyle: Style {
    public var title: TextStyle
    public var subtitle: TextStyle
    public var spacing: CGFloat
    public var insets: UIEdgeInsets

    public init(title: TextStyle = TitleSubtitleStyle.default.title, subtitle: TextStyle = TitleSubtitleStyle.default.subtitle, spacing: CGFloat = TitleSubtitleStyle.default.spacing, insets: UIEdgeInsets = TitleSubtitleStyle.default.insets) {
        self.title = title
        self.subtitle = subtitle
        self.spacing = spacing
        self.insets = insets
    }
}

public extension TitleSubtitleStyle {
    static let system = TitleSubtitleStyle(title: prototypeCell.textLabel?.style ?? TextStyle(font: .systemFont(ofSize: 17), color: .black, alignment: .left),
                                           subtitle: prototypeCell.detailTextLabel?.style ?? TextStyle(font: .systemFont(ofSize: 12), color: .black, alignment: .left),
                                           spacing: 3,
                                           insets: .zero)
    static var `default`: TitleSubtitleStyle { return DefaultStyling.current.titleSubtitle }
}

private let prototypeCell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
