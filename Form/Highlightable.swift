//
//  Highlightable.swift
//  Form
//
//  Created by Måns Bernhardt on 2017-08-11.
//  Copyright © 2017 iZettle. All rights reserved.
//

import UIKit
import Flow

/// Conforming types have a highlighted state that can be updated and observed.
public protocol Highlightable {
    var isHighlightedSignal: ReadWriteSignal<Bool> { get }
}

public extension Highlightable {
    var isHighlighted: Bool {
        get { return isHighlightedSignal.value }
        set { isHighlightedSignal.value = newValue }
    }
}

extension UILabel: Highlightable {
    public var isHighlightedSignal: ReadWriteSignal<Bool> {
        return signal(for: \.isHighlighted).distinct()
    }
}

extension UIImageView: Highlightable {
    public var isHighlightedSignal: ReadWriteSignal<Bool> {
        return signal(for: \.isHighlighted).distinct()
    }
}
