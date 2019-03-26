//
//  SectionBackgroundStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-10-25.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit

public struct SectionBackgroundStyle: Style {
    public var background: BackgroundStyle

    /// Separator to add for middle and bottom rows.
    public var topSeparator: InsettedStyle<SeparatorStyle>

    /// Separator to add for middle or top rows.
    public var bottomSeparator: InsettedStyle<SeparatorStyle>

    public init(background: BackgroundStyle, topSeparator: InsettedStyle<SeparatorStyle>, bottomSeparator: InsettedStyle<SeparatorStyle>) {
        self.background = background
        self.topSeparator = topSeparator
        self.bottomSeparator = bottomSeparator
    }
}

public extension SectionBackgroundStyle {
    var border: BorderStyle {
        get { return background.border }
        set { background.border = newValue }
    }

    var color: UIColor {
        get { return background.color }
        set { background.color = newValue }
    }
}

public extension SectionBackgroundStyle {
    static let none = SectionBackgroundStyle(background: .none, topSeparator: .none, bottomSeparator: .none)
    static let system = SectionBackgroundStyle(background: BackgroundStyle(color: .white, border: BorderStyle(width: UIScreen.main.thinestLineWidth, color: .systemSeparator, cornerRadius: 0)),
                                               topSeparator: .none,
                                               bottomSeparator: InsettedStyle(style: SeparatorStyle(width: UIScreen.main.thinestLineWidth, color: .systemSeparator), insets: prototypeGroupedTableView.separatorInset))

    static var systemSelected = SectionBackgroundStyle.system.restyled {
        $0.color = .systemSelection
        $0.border = .none
    }

    static let systemInsetted = SectionBackgroundStyle.system.restyled {
        $0.border.color = .clear
        $0.border.cornerRadius = 5
    }

    static var systemInsettedSelected = SectionBackgroundStyle.systemInsetted.restyled {
        $0.color = .systemSelection
    }

    static var `default`: SectionBackgroundStyle { return DefaultStyling.current.sectionBackground }
    static var `defaultSelected`: SectionBackgroundStyle { return DefaultStyling.current.sectionBackgroundSelected }
}

public extension SectionBackgroundStyle {
    var transparent: SectionBackgroundStyle { return restyled { $0.color = .clear } }
    var noBorders: SectionBackgroundStyle { return restyled { $0.border = .none } }
}

public extension UIColor {
    @nonobjc static let systemSelection = UIColor(white: 0.85, alpha: 1)
    @nonobjc static let systemSeparator = prototypeGroupedTableView.separatorColor ?? UIColor(white: 0.8, alpha: 1)
}
