//
//  ViewController.swift
//  HaptIQ
//
//  Created by Shreyansh on 29/10/25.
//

import UIKit

class ViewController: UIViewController {

    let label = UILabel()
    let button = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // Label setup
        label.text = "Hello, UIKit!"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24)
        label.frame = CGRect(x: 50, y: 200, width: 300, height: 50)
        view.addSubview(label)
        
        // Button setup
        button.setTitle("Change Text", for: .normal)
        button.frame = CGRect(x: 100, y: 300, width: 200, height: 50)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func buttonTapped() {
        label.text = "You tapped the button!"
    }
}
