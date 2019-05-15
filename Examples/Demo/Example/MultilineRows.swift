//
//  MultilineRows.swift
//  Example
//
//  Created by Nataliya Patsovska on 2019-05-15.
//  Copyright © 2019 iZettle. All rights reserved.
//

import UIKit
import Flow
import Form

extension UIViewController {
    func presentMultilineRows() -> Disposable {
        let shortTitle = "Short title"
        let shortSubtitle = "Short subtitle"
        let longTitle = "Long title that goes on multiple lines and has \nline break"
        let longSubtitle = "Long subtitle that goes on multiple lines and has \nline break"

        let style = TitleSubtitleStyle.default.restyled {
            $0.title = $0.title.multilined()
            $0.subtitle = $0.subtitle.multilined()
        }

        self.displayableTitle = "Test multiline rows"

        let form = FormView()
        let section = form.appendSection()

        section.appendRow(title: shortTitle, style: style.title).prepend("1")
        section.appendRow(title: longTitle, style: style.title).prepend("2")

        section.appendRow(title: shortTitle, subtitle: shortSubtitle, style: style).prepend("3")
        section.appendRow(title: shortTitle, subtitle: longSubtitle, style: style).prepend("4")
        section.appendRow(title: longTitle, subtitle: shortSubtitle, style: style).prepend("5")
        section.appendRow(title: longTitle, subtitle: longSubtitle, style: style).prepend("6")

        section.appendRow(title: longTitle, style: style.title).append(UISwitch()).prepend("7")
        section.appendRow(title: longTitle, subtitle: longSubtitle, style: style).append(UISwitch()).prepend("8")

        return self.install(form)
    }
}
