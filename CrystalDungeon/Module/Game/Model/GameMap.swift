//
//  GameMap.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 19.03.2026.
//

import Foundation

// MARK: - GameMap
final class GameMap {

    // MARK: - Properties
    private(set) var rooms: [Position: Room] = [:]

    var allPositions: [Position] {
        Array(rooms.keys)
    }

    // MARK: - Public
    func setRoom(_ room: Room, at position: Position) {
        rooms[position] = room
    }

    func room(at position: Position) -> Room? {
        rooms[position]
    }

    func clear() {
        rooms.removeAll()
    }
}
