//
//  Messages.swift
//  Messages
//
//  Created by Måns Bernhardt on 2018-04-19.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Presentation
import Form

struct Messages {
    let messages: ReadSignal<[Message]>
    let composeMessage: Presentation<ComposeMessage>
    let messageDetails: (Message) -> Presentation<MessageDetails>
}

struct Message: Decodable, Hashable {
    var title: String
    var body: String
}

extension Messages: Presentable {
    func materialize() -> (UIViewController, Disposable) {
        let split = UISplitViewController()
        split.preferredDisplayMode = UIDevice.current.userInterfaceIdiom == .pad ? .allVisible : .automatic

        let viewController = UIViewController()
        viewController.displayableTitle = "Messages"

        let bag = DisposeBag()

        bag += split.present(viewController, options: [ .defaults, .showInMaster ])

        let tableKit = TableKit<EmptySection, Message>(holdIn: bag)

        bag += messages.atOnce().onValue {
            tableKit.set(Table(rows: $0))
        }

        let splitDelegate = split.setupSplitDelegate(ownedBy: bag)
        let selection = MasterDetailSelection(elements: tableKit.readOnly(), isSame: ==, isCollapsed: splitDelegate.isCollapsedSignal)

        bag += selection.presentDetail(on: split) { indexAndElement in
            if let message = indexAndElement?.element {
                return DisposablePresentation(self.messageDetails(message))
            } else {
                return DisposablePresentation(Empty())
            }
        }

        bag += selection.bindTo(tableKit)

        bag += viewController.navigationItem.addItem(UIBarButtonItem(system: .compose), position: .right).onValueDisposePrevious {
            viewController.present(self.composeMessage).disposable
        }

        bag += viewController.install(tableKit)

        return (split, bag)
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

struct Empty: Presentable {
    func materialize() -> (UIViewController, Disposable) {
        return (UIViewController(), NilDisposer())
    }
}
