//
//  GamePresenter.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import Foundation

protocol GamePresenterProtocol: AnyObject {
    func viewDidLoad()
    func handle(command: String)
}

final class GamePresenter: GamePresenterProtocol {

    weak var view: GameViewProtocol?
    private let engine: GameEngine

    init(view: GameViewProtocol, engine: GameEngine) {
        self.view = view
        self.engine = engine
    }

    func viewDidLoad() {
        view?.display(output: "Game started")
    }

    func handle(command: String) {
        view?.display(output: command)
    }
}
