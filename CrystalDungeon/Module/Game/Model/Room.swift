//
//  Room.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import Foundation

// MARK: - Room
struct Room {
    let description: String
    var items: [Item]
    var isDark: Bool
    var monsterName: String?
}
