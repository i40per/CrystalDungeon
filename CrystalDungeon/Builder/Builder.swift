//
//  Builder.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import UIKit

// MARK: - Builder
final class Builder {

    static func createGameModule() -> UIViewController {
        let view = GameViewController()
        let engine = GameEngine()
        let presenter = GamePresenter(view: view, engine: engine)

        view.presenter = presenter

        return view
    }
}
