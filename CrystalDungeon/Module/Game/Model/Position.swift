//
//  Position.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import Foundation

// MARK: - Position
struct Position: Hashable {
    let x: Int
    let y: Int

    func moved(_ direction: Direction) -> Position {
        switch direction {
        case .north:
            return Position(x: x, y: y - 1)
        case .south:
            return Position(x: x, y: y + 1)
        case .east:
            return Position(x: x + 1, y: y)
        case .west:
            return Position(x: x - 1, y: y)
        }
    }
}
