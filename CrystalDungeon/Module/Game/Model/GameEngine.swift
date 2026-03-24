//
//  GameEngine.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import Foundation

// MARK: - GameEngine
final class GameEngine {

    // MARK: - Dependencies
    private let map = GameMap()
    private let player: Player

    // MARK: - State
    private var lastMessage: String?
    private var isGameWon = false
    private var isGameLost = false
    private var stepsRemaining = 0
    private var isConfigured = false

    // MARK: - Monster State
    private var previousPositionBeforeMonster = Position(x: 0, y: 0)
    private var monsterTimeRemaining = 0
    private var isMonsterEncounter = false

    // MARK: - Constants
    private let monsterNames = ["dragon", "orc", "goblin"]
    private let foodStepBonus = 5

    // MARK: - Initialization
    init() {
        player = Player(position: Position(x: 0, y: 0))
    }

    // MARK: - Public
    var isMonsterEncounterActive: Bool {
        isMonsterEncounter
    }

    func start() -> GameResult {
        guard isConfigured else {
            return GameResult(output: "Введите количество комнат\nи нажмите Отправить.")
        }

        return GameResult(output: buildOutput())
    }

    func configure(roomCount: Int) -> GameResult {
        let normalizedRoomCount = max(4, roomCount)

        resetGameState()
        setupWorld(roomCount: normalizedRoomCount)

        stepsRemaining = max(15, requiredStepsToWin() + 7)
        lastMessage = "Сгенерирован лабиринт из \(normalizedRoomCount) комнат."

        return GameResult(output: buildOutput())
    }

    func handle(_ command: Command) -> GameResult {
        guard isConfigured else {
            return GameResult(output: "Сначала введите количество комнат.")
        }

        if isGameWon {
            return GameResult(output: """
    Победа!
    Вы открыли chest и получили
    Holy Grail
    """)
        }

        if isGameLost {
            return GameResult(output: "Ходы закончились.\nИгрок погиб от голода в лабиринте.")
        }

        lastMessage = nil

        if isMonsterEncounter {
            return resolveMonsterEncounter(with: command)
        }

        if isCurrentRoomDarkWithoutLight() {
            if case .move = command {
                // Allowed
            } else {
                lastMessage = blockedCommandMessage(for: command)
                return GameResult(output: buildOutput())
            }
        }

        process(command)

        return GameResult(output: buildOutput())
    }

    func monsterTimerTick() -> GameResult {
        guard isMonsterEncounter else {
            return GameResult(output: buildOutput())
        }

        monsterTimeRemaining -= 1

        if monsterTimeRemaining <= 0 {
            applyMonsterTimeout()
        }

        return GameResult(output: buildOutput())
    }
}

// MARK: - Setup
private extension GameEngine {

    func resetGameState() {
        player.position = Position(x: 0, y: 0)
        player.inventory.removeAll()
        player.gold = 0

        isGameWon = false
        isGameLost = false
        isConfigured = true

        lastMessage = nil
        monsterTimeRemaining = 0
        isMonsterEncounter = false
        previousPositionBeforeMonster = Position(x: 0, y: 0)
    }

    func setupWorld(roomCount: Int) {
        map.clear()

        let positions = generatePositions(roomCount: roomCount)
        let startPosition = Position(x: 0, y: 0)

        for position in positions {
            let room = Room(
                description: position == startPosition ? "Стартовая комната." : "Обычная комната.",
                items: [],
                isDark: Bool.random() && position != startPosition,
                monsterName: nil
            )
            map.setRoom(room, at: position)
        }

        guard positions.count > 1 else { return }

        populateRequiredItems(in: positions, startPosition: startPosition)
    }

    func generatePositions(roomCount: Int) -> [Position] {
        guard roomCount > 0 else {
            return [Position(x: 0, y: 0)]
        }

        let columns = Int(ceil(sqrt(Double(roomCount))))
        let rows = Int(ceil(Double(roomCount) / Double(columns)))

        var positions: [Position] = []

        for y in 0..<rows {
            for x in 0..<columns where positions.count < roomCount {
                positions.append(Position(x: x, y: y))
            }
        }

        return positions
    }

    func populateRequiredItems(in positions: [Position], startPosition: Position) {
        var occupiedPositions: Set<Position> = [startPosition]

        let keyPosition = positions.first(where: { $0 != startPosition }) ?? positions[1]
        occupiedPositions.insert(keyPosition)

        let chestPosition = positions
            .filter { !occupiedPositions.contains($0) }
            .max(by: {
                manhattanDistance(from: startPosition, to: $0) < manhattanDistance(from: startPosition, to: $1)
            }) ?? positions.last!

        occupiedPositions.insert(chestPosition)

        if var keyRoom = map.room(at: keyPosition) {
            keyRoom.items.append(Item(type: .key, name: "key"))
            map.setRoom(keyRoom, at: keyPosition)
        }

        if var chestRoom = map.room(at: chestPosition) {
            chestRoom.items.append(Item(type: .chest, name: "chest"))
            map.setRoom(chestRoom, at: chestPosition)
        }

        var freePositions = positions
            .filter { !occupiedPositions.contains($0) }
            .shuffled()

        func takeFreePosition() -> Position? {
            guard !freePositions.isEmpty else { return nil }
            return freePositions.removeFirst()
        }

        if let torchPosition = takeFreePosition(),
           var torchRoom = map.room(at: torchPosition) {
            torchRoom.items.append(Item(type: .torchlight, name: "torch"))
            map.setRoom(torchRoom, at: torchPosition)
        }

        populateOptionalEntities(using: &freePositions)

        if let goldPosition = takeFreePosition(),
           var goldRoom = map.room(at: goldPosition) {
            goldRoom.items.append(Item(type: .gold, name: "gold"))
            map.setRoom(goldRoom, at: goldPosition)
        }
    }

    func populateOptionalEntities(using freePositions: inout [Position]) {
        let optionalEntities = ["food", "sword", "monster"].shuffled()

        for entity in optionalEntities {
            guard !freePositions.isEmpty else { break }

            let position = freePositions.removeFirst()

            switch entity {
            case "food":
                if var room = map.room(at: position) {
                    room.items.append(Item(type: .food, name: "food"))
                    map.setRoom(room, at: position)
                }

            case "sword":
                if var room = map.room(at: position) {
                    room.items.append(Item(type: .sword, name: "sword"))
                    map.setRoom(room, at: position)
                }

            case "monster":
                if var room = map.room(at: position) {
                    room.monsterName = monsterNames.randomElement() ?? "monster"
                    map.setRoom(room, at: position)
                }

            default:
                break
            }
        }
    }

    func requiredStepsToWin() -> Int {
        let startPosition = Position(x: 0, y: 0)

        guard let keyPosition = positionOfItem(.key),
              let chestPosition = positionOfItem(.chest) else {
            return 8
        }

        let toKey = manhattanDistance(from: startPosition, to: keyPosition)
        let toChest = manhattanDistance(from: keyPosition, to: chestPosition)

        return max(8, toKey + toChest)
    }

    func positionOfItem(_ itemType: ItemType) -> Position? {
        for (position, room) in map.rooms where room.items.contains(where: { $0.type == itemType }) {
            return position
        }
        return nil
    }

    func manhattanDistance(from: Position, to: Position) -> Int {
        abs(from.x - to.x) + abs(from.y - to.y)
    }
}

// MARK: - Command Processing
private extension GameEngine {

    func process(_ command: Command) {
        switch command {
        case .move(let direction):
            move(direction)

        case .get(let itemName):
            get(itemName)

        case .drop(let itemName):
            drop(itemName)

        case .eat(let itemName):
            eat(itemName)

        case .fight:
            fightMonster()

        case .open(let itemName):
            open(itemName)

        case .unknown(let value):
            lastMessage = "Неизвестная команда: \(value)"
        }
    }

    func move(_ direction: Direction) {
        let newPosition = player.position.moved(direction)

        guard map.room(at: newPosition) != nil else {
            lastMessage = "Нет прохода в направлении \(direction.rawValue)"
            return
        }

        previousPositionBeforeMonster = player.position
        player.position = newPosition

        stepsRemaining -= 1

        if stepsRemaining <= 0 {
            isGameLost = true
            lastMessage = "Ходы закончились.\nИгрок погиб от голода в лабиринте."
            return
        }

        lastMessage = "Игрок переместился: \(direction.rawValue)"

        if let room = map.room(at: player.position),
           room.monsterName != nil {
            startMonsterEncounter()
        }
    }

    func get(_ itemName: String) {
        guard var room = map.room(at: player.position) else { return }

        guard let index = room.items.firstIndex(where: {
            $0.name.lowercased() == itemName.lowercased()
        }) else {
            lastMessage = "Предмет \(itemName) не найден"
            return
        }

        let item = room.items[index]

        if item.type == .chest {
            lastMessage = "Нельзя поднять chest"
            return
        }

        if item.type == .gold {
            player.gold += 320
            room.items.remove(at: index)
            map.setRoom(room, at: player.position)

            lastMessage = "Подобрано золото (320 coins).\nБаланс: \(player.gold)"
            return
        }

        room.items.remove(at: index)
        player.inventory.append(item)
        map.setRoom(room, at: player.position)

        lastMessage = "Подобран предмет: \(item.name)"
    }

    func drop(_ itemName: String) {
        guard let index = player.inventory.firstIndex(where: {
            $0.name.lowercased() == itemName.lowercased()
        }) else {
            lastMessage = "В инвентаре нет предмета \(itemName)"
            return
        }

        let item = player.inventory.remove(at: index)

        guard var room = map.room(at: player.position) else { return }
        room.items.append(item)
        map.setRoom(room, at: player.position)

        lastMessage = "Предмет выброшен: \(item.name)"
    }

    func eat(_ itemName: String) {
        guard let index = player.inventory.firstIndex(where: {
            $0.name.lowercased() == itemName.lowercased()
        }) else {
            lastMessage = "В инвентаре нет предмета \(itemName)"
            return
        }

        let item = player.inventory[index]

        guard item.type == .food else {
            lastMessage = "Можно съесть только food"
            return
        }

        player.inventory.remove(at: index)
        stepsRemaining += foodStepBonus
        lastMessage = "Игрок съел food.\n\(gainedStepsPhrase(for: foodStepBonus))"
    }

    func fightMonster() {
        guard player.hasItem(of: .sword) else {
            lastMessage = "Для команды fight нужен sword"
            return
        }

        guard var room = map.room(at: player.position),
              room.monsterName != nil else {
            lastMessage = "В комнате нет монстра"
            return
        }

        room.monsterName = nil
        map.setRoom(room, at: player.position)

        isMonsterEncounter = false
        monsterTimeRemaining = 0
        lastMessage = "Монстр уничтожен"
    }

    func open(_ itemName: String) {
        guard itemName.lowercased() == "chest" else {
            lastMessage = "Можно открыть только chest"
            return
        }

        guard let room = map.room(at: player.position) else { return }

        let hasChestInRoom = room.items.contains { $0.type == .chest }
        guard hasChestInRoom else {
            lastMessage = "В комнате нет chest"
            return
        }

        let hasKey = player.inventory.contains { $0.type == .key }
        guard hasKey else {
            lastMessage = "Нужен key, чтобы открыть chest"
            return
        }

        isGameWon = true
        lastMessage = """
    Победа!
    Вы открыли chest и получили
    Holy Grail
    """
    }
}

// MARK: - Monster Handling
private extension GameEngine {

    func startMonsterEncounter() {
        isMonsterEncounter = true
        monsterTimeRemaining = 5
    }

    func resolveMonsterEncounter(with command: Command) -> GameResult {
        let outcome = Int.random(in: 0...2)

        switch outcome {
        case 0:
            let damage = applyMonsterDamage()
            player.position = previousPositionBeforeMonster
            isMonsterEncounter = false
            monsterTimeRemaining = 0
            lastMessage = "Монстр атаковал игрока.\nИгрок отброшен назад.\n\(lostStepsPhrase(for: damage))"

        case 1:
            let damage = applyMonsterDamage()
            isMonsterEncounter = false
            monsterTimeRemaining = 0

            process(command)

            if let lastMessage {
                self.lastMessage = "Монстр ранил игрока.\n\(lostStepsPhrase(for: damage))\n\(lastMessage)"
            } else {
                lastMessage = "Монстр ранил игрока.\n\(lostStepsPhrase(for: damage))"
            }

        default:
            isMonsterEncounter = false
            monsterTimeRemaining = 0
            process(command)
        }

        return GameResult(output: buildOutput())
    }

    func applyMonsterTimeout() {
        let damage = applyMonsterDamage()

        player.position = previousPositionBeforeMonster
        isMonsterEncounter = false
        monsterTimeRemaining = 0
        lastMessage = "Время вышло.\nМонстр атаковал игрока.\n\(lostStepsPhrase(for: damage))"
    }

    func applyMonsterDamage() -> Int {
        let damage = max(1, Int(ceil(Double(max(1, stepsRemaining)) * 0.1)))
        stepsRemaining -= damage

        if stepsRemaining <= 0 {
            isGameLost = true
            lastMessage = "Ходы закончились.\nИгрок погиб от голода в лабиринте."
        }

        return damage
    }

    func stepWord(for value: Int) -> String {
        let lastTwoDigits = value % 100
        let lastDigit = value % 10

        if (11...14).contains(lastTwoDigits) {
            return "шагов"
        }

        switch lastDigit {
        case 1:
            return "шаг"
        case 2, 3, 4:
            return "шага"
        default:
            return "шагов"
        }
    }
    
    func lostStepsPhrase(for value: Int) -> String {
        if value == 1 {
            return "Потерян 1 шаг."
        }

        return "Потеряно \(value) \(stepWord(for: value))."
    }

    func gainedStepsPhrase(for value: Int) -> String {
        return "Шаги увеличены на \(value)."
    }
}

// MARK: - Output
private extension GameEngine {

    func buildOutput() -> String {
        if isGameWon {
            return """
    Победа!
    Вы открыли chest и получили
    Holy Grail
    """
        }

        if isGameLost {
            return "Ходы закончились.\nИгрок погиб от голода в лабиринте."
        }

        let roomText = currentRoomText()

        guard let lastMessage else {
            return roomText
        }

        return "\(lastMessage)\n\(roomText)"
    }

    func currentRoomText() -> String {
        guard let room = map.room(at: player.position) else {
            return "Комната не найдена"
        }

        let doors = availableDirections(from: player.position)
        let doorList = doors.map(\.rawValue).joined(separator: ", ")

        let isDarkWithoutLight = isCurrentRoomDarkWithoutLight()

        let itemsList: String
        if isDarkWithoutLight {
            itemsList = "unknown"
        } else {
            itemsList = room.items.isEmpty
                ? "none"
                : room.items.map(\.name).joined(separator: ", ")
        }

        let inventoryList = player.inventory.isEmpty
            ? "empty"
            : player.inventory.map(\.name).joined(separator: ", ")

        let monsterText: String
        if let monsterName = room.monsterName {
            if isMonsterEncounter {
                monsterText = "There is an evil \(monsterName) in the room!\nTime left: [\(monsterTimeRemaining)]"
            } else {
                monsterText = "There is an evil \(monsterName) in the room!"
            }
        } else {
            monsterText = ""
        }

        return """
        You are in the room [\(player.position.x), \(player.position.y)].
        There are [\(doors.count)] doors: [\(doorList)].
        Items in the room: [\(itemsList)].
        \(roomDescription(for: room))
        \(monsterText)
        Inventory: [\(inventoryList)]
        Gold: [\(player.gold)]
        Steps remaining: [\(stepsRemaining)]
        """
    }

    func roomDescription(for room: Room) -> String {
        if isCurrentRoomDarkWithoutLight() {
            return "Can’t see anything in this dark place!"
        }

        var lines: [String] = []

        if room.description == "Стартовая комната." {
            lines.append("Стартовая комната.")
        } else if room.items.isEmpty {
            lines.append("Комната пуста.")
        } else {
            lines.append("Обычная комната.")
        }

        if room.items.contains(where: { $0.type == .chest }) {
            lines.append("В комнате стоит сундук.")
        }

        if room.items.contains(where: { $0.type == .key }) {
            lines.append("В комнате лежит ключ.")
        }

        if room.items.contains(where: { $0.type == .torchlight }) {
            lines.append("В комнате лежит факел.")
        }

        if room.items.contains(where: { $0.type == .food }) {
            lines.append("В комнате лежит еда.")
        }

        if room.items.contains(where: { $0.type == .sword }) {
            lines.append("В комнате лежит меч.")
        }

        if room.items.contains(where: { $0.type == .gold }) {
            lines.append("В комнате лежит золото.")
        }

        return lines.joined(separator: "\n")
    }

    func availableDirections(from position: Position) -> [Direction] {
        Direction.allCases.filter { direction in
            let candidate = position.moved(direction)
            return map.room(at: candidate) != nil
        }
    }

    func isCurrentRoomDarkWithoutLight() -> Bool {
        guard let room = map.room(at: player.position) else {
            return false
        }

        let hasTorchInInventory = player.hasItem(of: .torchlight)
        let hasTorchInRoom = room.items.contains { $0.type == .torchlight }

        return room.isDark && !hasTorchInInventory && !hasTorchInRoom
    }

    func blockedCommandMessage(for command: Command) -> String {
        switch command {
        case .get(let itemName):
            return "Команда get \(itemName) недоступна\nв тёмной комнате"

        case .drop(let itemName):
            return "Команда drop \(itemName) недоступна\nв тёмной комнате"

        case .eat(let itemName):
            return "Команда eat \(itemName) недоступна\nв тёмной комнате"

        case .fight:
            return "Команда fight недоступна\nв тёмной комнате"

        case .open(let itemName):
            return "Команда open \(itemName) недоступна\nв тёмной комнате"

        case .unknown(let value):
            return "Неизвестная команда: \(value)"

        case .move:
            return ""
        }
    }
}
