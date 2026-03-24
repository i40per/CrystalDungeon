//
//  SceneDelegate.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Properties
    var window: UIWindow?

    // MARK: - UIWindowSceneDelegate
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = Builder.createGameModule()
        window.makeKeyAndVisible()

        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) { }

    func sceneDidBecomeActive(_ scene: UIScene) { }

    func sceneWillResignActive(_ scene: UIScene) { }

    func sceneWillEnterForeground(_ scene: UIScene) { }

    func sceneDidEnterBackground(_ scene: UIScene) { }
}
