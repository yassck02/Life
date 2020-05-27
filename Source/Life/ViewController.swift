//
//  ViewController.swift
//  Life
//
//  Created by Connor yass on 5/27/20.
//  Copyright © 2020 Chinaberry Tech, LLC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var lifeView: LifeMTKView!
    
    init() {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        addLifeView()
    }
    
    private func addLifeView() {
        lifeView = LifeMTKView(width: 100, height: 100)
        
        view.addSubview(lifeView)
        lifeView.translatesAutoresizingMaskIntoConstraints = false
        lifeView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        lifeView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        lifeView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        lifeView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let _ = touches.first {
            lifeView.step()
        }
    }
}
