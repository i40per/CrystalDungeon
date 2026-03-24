//
//  Command.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 19.03.2026.
//

import Foundation

// MARK: - Command
enum Command {
    case move(Direction)
    case get(String)
    case drop(String)
    case eat(String)
    case fight
    case open(String)
    case unknown(String)
}
