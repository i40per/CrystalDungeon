//
//  Player.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 19.03.2026.
//

import Foundation

// MARK: - Player
final class Player {

    // MARK: - Properties
    var position: Position
    var inventory: [Item]
    var gold: Int

    // MARK: - Initialization
    init(position: Position, inventory: [Item] = [], gold: Int = 0) {
        self.position = position
        self.inventory = inventory
        self.gold = gold
    }

    // MARK: - Public
    func hasItem(of type: ItemType) -> Bool {
        inventory.contains { $0.type == type }
    }
}
