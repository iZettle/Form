//
//  AffixView.swift
//  Form
//
//  Created by Måns Bernhardt on 2016-01-15.
//  Copyright © 2016 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Whether the affix should be positioned to the left or right.
public enum AffixPosition {
    case left
    case right
}

/// Conforming types provides an affix position.
public protocol AffixPositional {
    var affixPosition: AffixPosition { get }
}

public extension AffixPositional {
    var affixPosition: AffixPosition { return .right }
}

/// A stack view holding a view and an affixView where the affixView position is decided by `affixPosition`.
public final class AffixView<View: UIView, AffixView: UIView>: UIStackView {
    public let view: View
    public let affixView: AffixView

    public var affixPosition: AffixPosition {
        didSet {
            switch affixPosition {
            case .left: orderedViews = [affixView, view]
            case .right: orderedViews = [view, affixView]
            }
        }
    }

    public init(view: View, affixView: AffixView, spacing: CGFloat = 0, affixPosition: AffixPosition = .right) {
        self.view = view
        self.affixView = affixView
        self.affixPosition = affixPosition
        var views = [UIView]()

        switch affixPosition {
        case .left: views += [ affixView, view ]
        case .right: views += [ view, affixView ]
        }

        super.init(frame: .zero)
        views.forEach(addArrangedSubview)

        self.spacing = spacing
        distribution = .equalCentering
        axis = .horizontal
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AffixView: SignalProvider where View: SignalProvider {
    public typealias Value = View.Value
    public typealias Kind = View.Kind

    public var providedSignal: CoreSignal<Kind, Value> {
        return view.atValue {
            if let affixPositional = $0 as? AffixPositional {
                self.affixPosition = affixPositional.affixPosition
            }
        }
    }
}
