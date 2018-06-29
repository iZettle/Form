//
//  Login.swift
//  Example
//
//  Created by Måns Bernhardt on 2018-06-12.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Form

extension UIViewController {
    func presentLogin() -> Future<()> {
        return Future { completion in
            let bag = DisposeBag()
            self.displayableTitle = "Login"

            let form = FormView()
            let section = form.appendSection()

            let email = UITextField(placeholder: "example@mail.com", style: .email)
            let password = UITextField(placeholder: "•••••••")
            password.isSecureTextEntry = true

            section.appendRow(title: "Email").append(email)
            section.appendRow(title: "Password").append(password)
            activate(email.leftAnchor == password.leftAnchor)

            let login = UIButton(title: "Login")
            form.appendSection().append(login)

            bag += combineLatest(email, password).map { email, password in
                email.contains("@") && password.count > 1
            }.atOnce().bindTo(login, \.isEnabled)

            bag += login.onValue {
                completion(.success)
            }

            bag += self.navigationItem.addItem(UIBarButtonItem(system: .cancel), position: .left).onValue {
                completion(.failure(CancelError()))
            }

            bag += self.install(form) { scrollView in
                bag += scrollView.chainAllControlResponders(shouldLoop: true, returnKey: .next)
                email.becomeFirstResponder()
            }

            return bag
        }
    }
}

struct CancelError: Error {}
