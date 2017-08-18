//
//  Tile.swift
//  Mines
//
//  Created by Haven Barnes on 8/18/17.
//  Copyright © 2017 Azing. All rights reserved.
//

import UIKit

class Tile: UIButton {
    var x: Int = 0
    var y: Int = 0
    var cleared = false
    
    /// Returns adjacent tiles
    /// Accepts grid as context
    func neighbors(_ grid: [[Tile]]) -> [Tile] {
        
        var neighbors: [Tile] = []
        for colDelta in -1...1 {
            for rowDelta in -1...1 {
                // Don't include self
                guard !(colDelta == 0 && rowDelta == 0) else { continue }
                let x = self.x + colDelta
                let y = self.y + rowDelta
                guard x >= 0 && x <= 3
                    && y>=0 && y <= 3 else {
                        continue
                }
                neighbors.append(grid[x][y])
            }
        }
        
        cleared = true
        return neighbors
    }
}
