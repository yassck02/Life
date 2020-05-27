//
//  SceneDelegate.swift
//  Mandelbrot-Set
//
//  Created by Connor yass on 5/25/20.
//  Copyright © 2020 Chinaberry Tech, LLC. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let vc = ViewController()

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = vc
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
