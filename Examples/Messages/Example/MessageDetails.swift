//
//  MessageDetails.swift
//  Messages
//
//  Created by Måns Bernhardt on 2018-04-19.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Presentation
import Form

struct MessageDetails {
    let message: Message
    let delete: Presentation<Alert<()>>
}

extension MessageDetails: Presentable {
    func materialize() -> (UIViewController, Disposable) {
        // Setup view controller and views
        let viewController = UIViewController()
        viewController.displayableTitle = message.title

        let form = FormView()
        let section = form.appendSection()

        section.appendRow(title: "Title").append(message.title)
        section.appendRow(title: "Body").append(message.body, style: TextStyle.defaultDetail.multilined())

        let deleteButton = UIButton(title: "Delete")
        form.appendSection().appendRow(deleteButton)

        // Setup event handling
        let bag = DisposeBag()

        bag += deleteButton.onValueDisposePrevious {
            viewController.present(self.delete).disposable
        }

        bag += viewController.install(form)

        return (viewController, bag)

    }
}
