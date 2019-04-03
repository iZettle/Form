//
//  DefaultStyling.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-02-25.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Default styles used when no explict styling (or `.default`) is used.
/// The currently used defaults can be changed by modifiying `DefaultStyling.current`.
/// By calling `DefaultStyling.lockCurrent()` you can lock `.current` from further changes.
public struct DefaultStyling: Style {
    public var text: TextStyle
    public var field: FieldStyle
    public var detailText: TextStyle
    public var titleSubtitle: TitleSubtitleStyle

    public var button: ButtonStyle
    public var barButton: BarButtonStyle

    public var `switch`: SwitchStyle
    public var segmentedControl: SegmentedControlStyle

    public var sectionGrouped: DynamicSectionStyle
    public var sectionPlain: DynamicSectionStyle

    public var formGrouped: DynamicFormStyle
    public var formPlain: DynamicFormStyle

    public var sectionBackground: SectionBackgroundStyle
    public var sectionBackgroundSelected: SectionBackgroundStyle

    public var scrollView: UIScrollView.Type
    public var plainTableView: UITableView.Type
    public var groupedTableView: UITableView.Type
    public var collectionView: UICollectionView.Type

    public init(text: TextStyle, field: FieldStyle, detailText: TextStyle, titleSubtitle: TitleSubtitleStyle, button: ButtonStyle, barButton: BarButtonStyle, `switch`: SwitchStyle, segmentedControl: SegmentedControlStyle, sectionGrouped: DynamicSectionStyle, sectionPlain: DynamicSectionStyle, formGrouped: DynamicFormStyle, formPlain: DynamicFormStyle, sectionBackground: SectionBackgroundStyle, sectionBackgroundSelected: SectionBackgroundStyle, scrollView: UIScrollView.Type, plainTableView: UITableView.Type, groupedTableView: UITableView.Type, collectionView: UICollectionView.Type) {
        self.text = text
        self.field = field
        self.detailText = detailText
        self.titleSubtitle = titleSubtitle
        self.button = button
        self.barButton = barButton
        self.`switch` = `switch`
        self.segmentedControl = segmentedControl
        self.sectionGrouped = sectionGrouped
        self.sectionPlain = sectionPlain
        self.formGrouped = formGrouped
        self.formPlain = formPlain
        self.sectionBackground = sectionBackground
        self.sectionBackgroundSelected = sectionBackgroundSelected
        self.scrollView = scrollView
        self.plainTableView = plainTableView
        self.groupedTableView = groupedTableView
        self.collectionView = collectionView
    }
}

public extension DefaultStyling {
    static let system = DefaultStyling()
    static var current: DefaultStyling {
        get { return currentDefaults }
        set {
            guard defaultsLockCount == 0 else {
                print("Warning, defaults are locked and can't be modified")
                return
            }
            currentDefaults = newValue
        }
    }
}

public extension DefaultStyling {
    /// Locks `.current` from further changes.
    /// - Returns: Disposable for unlocking.
    /// - Note: Many can separately hold on to the lock, and it won't be fully unlocked until all have unlocked.
    static func lockCurrent() -> Disposable {
        defaultsLockCount += 1
        return Disposer { defaultsLockCount -= 1 }
    }
}

public extension UIScrollView {
    @nonobjc static var `default`: UIScrollView {
        return DefaultStyling.current.scrollView.init()
    }
}

public extension UITableView {
    @nonobjc static var plain: UITableView {
        return DefaultStyling.current.plainTableView.init(frame: .zero, style: .plain)
    }

    @nonobjc static var grouped: UITableView {
        return DefaultStyling.current.groupedTableView.init(frame: .zero, style: .grouped)
    }

    static func defaultTable(for style: UITableView.Style) -> UITableView {
        switch style {
        case .plain: return .plain
        case .grouped: return .grouped
        @unknown default:
            assertionFailure("Unknown UITableView.Style")
            return .plain
        }
    }
}

public extension UICollectionView {
    static func defaultCollection(withLayout layout: UICollectionViewLayout) -> UICollectionView {
        return DefaultStyling.current.collectionView.init(frame: .zero, collectionViewLayout: layout)
    }
}

internal final class DefaultScrollView: UIScrollView { }

private extension DefaultStyling {
    init() {
        text = .system
        field = .system
        detailText = .systemDetail
        titleSubtitle = .system

        button = .system
        barButton = .system

        `switch` = .system
        segmentedControl = .system

        sectionGrouped = .systemGrouped
        sectionPlain = .systemPlain

        formGrouped = .systemGrouped
        formPlain = .systemPlain

        sectionBackground = .system
        sectionBackgroundSelected = .systemSelected

        scrollView = systemScrollView
        plainTableView = UITableView.self
        groupedTableView = UITableView.self
        collectionView = UICollectionView.self
    }
}

private let systemScrollView: UIScrollView.Type = {
    DefaultScrollView.self.appearance().backgroundColor = UITableView(frame: .zero, style: .grouped).backgroundColor
    return DefaultScrollView.self
}()

private var currentDefaults: DefaultStyling = .system
private var defaultsLockCount = 0
