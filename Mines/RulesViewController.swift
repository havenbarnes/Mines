//
//  RulesViewController.swift
//  Mines
//
//  Created by Haven Barnes on 8/19/17.
//  Copyright © 2017 Azing. All rights reserved.
//r

import UIKit

class RulesViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let swipe = UISwipeGestureRecognizer(target: self,
                                            action: #selector(backButtonPressed(_:)))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
