//
// Copyright © 2019 iZettle. All rights reserved.
//

import Flow

public extension TextStyle {

    /// When `dynamicTypeMapping` is set, on iOS 11 you can retrieve scaled version of your font.
    /// Works for standard and custom fonts.
    ///
    /// - Note: UIKit doesn't allow the scaling of already scaled fonts so if you're using `dynamicTypeMapping` make sure to not set an already scaled font to your text style.
    var scaledFont: UIFont {
        guard #available(iOS 11.0, *), let fontTextStyle = dynamicTypeMapping else {
            return font
        }
        let fontMetrics = UIFontMetrics(forTextStyle: fontTextStyle)
        let traits = UITraitCollection(preferredContentSizeCategory: contentSizeCategory?.value ?? .large)
        let scaledFont = fontMetrics.scaledFont(for: font, compatibleWith: traits)
        return scaledFont
    }
}

extension TextStyle {
    static let contentSizeObserver = DynamicTypeContentSizeObserver()
}

final class DynamicTypeContentSizeObserver {
    let getCurrentrPeferredContentSizeCategory: () -> UIContentSizeCategory
    let observedNotification: Notification.Name
    let userInfoKey: String

    init(getCurrentrPeferredContentSizeCategory: @escaping () -> UIContentSizeCategory = {
            UIApplication.shared.preferredContentSizeCategory
        },
         observedNotification: Notification.Name = UIContentSizeCategory.didChangeNotification,
         userInfoKey: String = UIContentSizeCategory.newValueUserInfoKey) {
        self.getCurrentrPeferredContentSizeCategory = getCurrentrPeferredContentSizeCategory
        self.observedNotification = observedNotification
        self.userInfoKey = userInfoKey
    }

    var contentSizeCategory: ReadSignal<UIContentSizeCategory> {
        return NotificationCenter.default.signal(forName: observedNotification).compactMap { note in
            return note.userInfo?[self.userInfoKey] as? UIContentSizeCategory
        }.readable(getValue: { () -> UIContentSizeCategory in
            return self.getCurrentrPeferredContentSizeCategory()
        })
    }
}
