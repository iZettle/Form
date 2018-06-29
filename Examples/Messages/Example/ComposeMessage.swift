//
//  ComposeMessage.swift
//  Messages
//
//  Created by Måns Bernhardt on 2018-04-19.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Presentation
import Form

struct ComposeMessage { }

extension ComposeMessage: Presentable {
    func materialize() -> (UIViewController, Future<Message>) {
        // Setup view controller and views
        let viewController = UIViewController()
        viewController.displayableTitle = "Compose Message"

        let form = FormView()
        let section = form.appendSection()

        let title = section.appendRow(title: "Title").append(UITextField(placeholder: "title"))
        let body = section.appendRow(title: "Body").append(UITextField(placeholder: "body"))

        return (viewController, Future { completion in
            // Setup event handling
            let bag = DisposeBag()

            bag += viewController.navigationItem.addItem(UIBarButtonItem(system: .cancel), position: .left).onValue {
                completion(.failure(PresentError.dismissed))
            }

            bag += viewController.navigationItem.addItem(UIBarButtonItem(system: .save), position: .right).onValue {
                let message = Message(title: title.value, body: body.value)
                completion(.success(message))
            }

            bag += viewController.install(form) { scrollView in
                bag += scrollView.chainAllControlResponders(shouldLoop: true, returnKey: .next)
                title.provider.becomeFirstResponder()
            }

            return bag
        })
    }
}
