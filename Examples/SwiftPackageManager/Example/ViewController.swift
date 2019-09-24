//
//  ViewController.swift
//  Example
//
//  Created by Robin Enhorn on 2019-09-23.
//  Copyright © 2019 iZettle. All rights reserved.
//

import UIKit
import Form

class ViewController: UIViewController {

    let messageLabel: UILabel = {
        let label = UILabel(value: "Hello Form!", style: .default)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24.0, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.embedView(
            FormView(
                sections: [messageLabel],
                style: .default
            )
        )
    }

}
