//
//  Room.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import Foundation

struct Room {
    let position: Position
    var exits: [Direction: Position]
    var items: [Item]
    
    init(position: Position,
         exits: [Direction: Position] = [:],
         items: [Item] = []) {
        self.position = position
        self.exits = exits
        self.items = items
    }
}
