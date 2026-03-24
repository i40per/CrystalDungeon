//
//  Direction.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import Foundation

// MARK: - Direction
enum Direction: String, CaseIterable {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"

    var opposite: Direction {
        switch self {
        case .north:
            return .south
        case .south:
            return .north
        case .east:
            return .west
        case .west:
            return .east
        }
    }
}
