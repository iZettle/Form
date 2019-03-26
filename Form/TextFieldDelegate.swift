//
//  TextFieldDelegate.swift
//  Form
//
//  Created by Måns Bernhardt on 2018-10-17.
//  Copyright © 2018 iZettle. All rights reserved.
//

import Flow
import UIKit

public final class TextFieldDelegate: NSObject, UITextFieldDelegate {
    private var didEndEditingCallbacker = Callbacker<()>()

    public var shouldBeginEditing = Delegate<String, Bool>()
    public var shouldEndEditing = Delegate<String, Bool>()
    public var shouldChangeCharacters = Delegate<(current: String, range: Range<String.Index>, replacementString: String), Bool>()
    public var shouldReturn = Delegate<String, Bool>()
    public var shouldClear = Delegate<String, Bool>()

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return shouldBeginEditing.call(textField.value) ?? true
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldEndEditing.call(textField.value) ?? true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        didEndEditingCallbacker.callAll()
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let range = Range(range, in: textField.value) else { return true }
        return shouldChangeCharacters.call((textField.value, range, string)) ?? true
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return shouldClear.call(textField.value) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return shouldReturn.call(textField.value) ?? true
    }
}

public extension TextFieldDelegate {
    var didEndEditing: Signal<()> {
        return Signal(callbacker: didEndEditingCallbacker)
    }

    /// Return true whether the proposed updated text should be accepted or not.
    /// - Note: Is based on `shouldChangeCharacters` so only one of the two can be used at a time.
    var shouldChangeToProposedText: Delegate<String, Bool> {
        return Delegate { isValidNewString in
            self.shouldChangeCharacters.set { text, range, replacementString in
                let proposedText = text.replacingCharacters(in: range, with: replacementString)
                return isValidNewString(proposedText)
            }
        }
    }
}

public extension UITextField {
    func install(_ delegate: UITextFieldDelegate) -> Disposable {
        self.delegate = delegate
        return Disposer {
            _ = delegate // Hold on to
            self.delegate = nil
        }
    }
}
