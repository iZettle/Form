//
//  AppDelegate.swift
//  Example
//
//  Created by Måns Bernhardt on 2018-04-17.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Form

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let bag = DisposeBag()
    var window: UIWindow?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let rootController = UIViewController()

        let navigationController = UINavigationController(rootViewController: rootController)

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        bag += rootController.presentContents()

        return true
    }
}
