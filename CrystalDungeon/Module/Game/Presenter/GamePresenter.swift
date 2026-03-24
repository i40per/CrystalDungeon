//
//  GamePresenter.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import Foundation

// MARK: - GamePresenterProtocol
protocol GamePresenterProtocol: AnyObject {
    func viewDidLoad()
    func handle(command: String)
}

// MARK: - GamePresenter
final class GamePresenter: GamePresenterProtocol {

    // MARK: - Properties
    weak var view: GameViewProtocol?

    private let engine: GameEngine
    private var isWaitingForRoomCount = true
    private var monsterTimer: Timer?

    // MARK: - Initialization
    init(view: GameViewProtocol, engine: GameEngine) {
        self.view = view
        self.engine = engine
    }

    deinit {
        monsterTimer?.invalidate()
    }

    // MARK: - GamePresenterProtocol
    func viewDidLoad() {
        view?.setWaitingForRoomCountState()

        let result = engine.start()
        view?.display(output: result.output)
    }

    func handle(command: String) {
        let trimmedCommand = command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if isWaitingForRoomCount {
            handleRoomCountInput(trimmedCommand)
            return
        }

        let parsedCommand = parseCommand(from: trimmedCommand)
        let result = engine.handle(parsedCommand)

        view?.display(output: result.output)
        updateMonsterTimerIfNeeded()
    }
}

// MARK: - Private
private extension GamePresenter {

    func handleRoomCountInput(_ input: String) {
        guard let roomCount = Int(input), roomCount >= 4 else {
            view?.setWaitingForRoomCountState()
            view?.display(output: "Введите корректное количество комнат. Минимум: 4")
            return
        }

        isWaitingForRoomCount = false
        view?.setGameCommandsState()

        let result = engine.configure(roomCount: roomCount)
        view?.display(output: result.output)

        updateMonsterTimerIfNeeded()
    }

    func parseCommand(from input: String) -> Command {
        guard !input.isEmpty else {
            return .unknown("empty")
        }

        switch input {
        case "n":
            return .move(.north)
        case "s":
            return .move(.south)
        case "e":
            return .move(.east)
        case "w":
            return .move(.west)
        case "fight":
            return .fight
        case "open chest":
            return .open("chest")
        default:
            break
        }

        if input.hasPrefix("get ") {
            let itemName = String(input.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            return itemName.isEmpty ? .unknown(input) : .get(itemName)
        }

        if input.hasPrefix("drop ") {
            let itemName = String(input.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            return itemName.isEmpty ? .unknown(input) : .drop(itemName)
        }

        if input.hasPrefix("eat ") {
            let itemName = String(input.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            return itemName.isEmpty ? .unknown(input) : .eat(itemName)
        }

        return .unknown(input)
    }

    func updateMonsterTimerIfNeeded() {
        monsterTimer?.invalidate()
        monsterTimer = nil

        guard engine.isMonsterEncounterActive else { return }

        monsterTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            let result = self.engine.monsterTimerTick()
            self.view?.display(output: result.output)

            if !self.engine.isMonsterEncounterActive {
                timer.invalidate()
                self.monsterTimer = nil
            }
        }
    }
}
