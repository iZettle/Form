//
//  Messages.swift
//  Example
//
//  Created by Måns Bernhardt on 2018-06-12.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Form

struct Message: Decodable, Hashable {
    var title: String
    var body: String
}

extension UIViewController {
    func presentComposeMessage() -> Future<Message> {
        self.displayableTitle = "Compose Message"

        let form = FormView()
        let section = form.appendSection()

        let title = section.appendRow(title: "Title").append(UITextField(placeholder: "title"))
        let body = section.appendRow(title: "Body").append(UITextField(placeholder: "body"))

        let isValid = combineLatest(title, body).map {
            !$0.isEmpty && !$1.isEmpty
        }

        let cancel = navigationItem.addItem(UIBarButtonItem(system: .cancel), position: .left)
        let save = navigationItem.addItem(UIBarButtonItem(system: .save), position: .right)

        return Future { completion in
            let bag = DisposeBag()

            bag += isValid.atOnce().bindTo(save, \.isEnabled)

            bag += save.onValue {
                let message = Message(title: title.value, body: body.value)
                completion(.success(message))
            }

            bag += cancel.onValue {
                completion(.failure(CancelError()))
            }

            bag += self.install(form) { scrollView in
                bag += scrollView.chainAllControlResponders(shouldLoop: true, returnKey: .next)
                title.provider.becomeFirstResponder()
            }

            return bag
        }
    }
}

extension UIViewController {
    func present(messages: ReadSignal<[Message]>) -> Disposable {
        displayableTitle = "Messages"
        let bag = DisposeBag()

        let tableKit = TableKit<EmptySection, Message>()

        bag += messages.atOnce().onValue {
            tableKit.set(Table(rows: $0))
        }

        bag += install(tableKit)

        return bag
    }
}

extension Message: Reusable {
    static func makeAndConfigure() -> (make: RowView, configure: (Message) -> Disposable) {
        let row = RowView(title: "", subtitle: "")
        return (row, { message in
            row.title = message.title
            row.subtitle = message.body
            return NilDisposer()
        })
    }
}

struct CancelError: Error {}

let messagesJSON = """
[
{ "title" : "Introducing Flow", "body" : "Asynchronous programming made easy" },
{ "title" : "Introducing Presentation", "body" : "Formalizing presentations from model to result" },
{ "title" : "Introducing Form", "body" : "Layout, styling, and events" },
]
"""

let testMessages: [Message] = {
    let decoder = JSONDecoder()
    return try! decoder.decode([Message].self, from: messagesJSON.data(using: .utf8)!)
}()
