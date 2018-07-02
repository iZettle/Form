//
//  AppDelegate.swift
//  Messages
//
//  Created by Måns Bernhardt on 2018-04-17.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Presentation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let bag = DisposeBag()

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let messages = Messages(messages: testMessages)

        let window = UIWindow(frame: UIScreen.main.bounds)
        bag += window.present(messages, options: .embedInNavigationController)

        return true
    }
}

extension Messages {
    init(messages: [Message]) {
        let messagesSignal = ReadWriteSignal(messages)
        self.messages = messagesSignal.readOnly()

        composeMessage = Presentation(ComposeMessage(), style: .modally(presentationStyle: .formSheet)).onValue { message in
            messagesSignal.value.insert(message, at: 0)
        }

        messageDetails = { message in
            let cancel = Alert.Action(title: "Cancel") { }
            let delete = Alert.Action(title: "Delete") {
                guard let i = messagesSignal.value.index(of: message) else { return }
                messagesSignal.value.remove(at: i)
            }
            let deleteAlert = Alert(title: "Delete message", message: "Are you sure you want to delete the message?", actions: cancel, delete)

            return Presentation(MessageDetails(message: message, delete: Presentation(deleteAlert)))
        }
    }
}

let messagesJSON = """
[
{ "title" : "message1", "body" : "body1" },
{ "title" : "message2", "body" : "body2" },
{ "title" : "message3", "body" : "body3" },
]
"""

let testMessages: [Message] = {
    let decoder = JSONDecoder()
    return try! decoder.decode([Message].self, from: messagesJSON.data(using: .utf8)!)
}()
