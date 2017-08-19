//
//  ViewController.swift
//  Mines
//
//  Created by Haven Barnes on 8/8/17.
//  Copyright © 2017 Azing. All rights reserved.
//

import UIKit

enum GameState {
    case initialized
    case inProgress
    case cleared
    case ended
}

class GameViewController: UIViewController {
    
    @IBOutlet var hudElements: [UIView]!
    
    @IBOutlet weak var bombImage: UIImageView!
    @IBOutlet weak var bombLabel: UILabel!
    
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var levelLabelContainer: UIView!
    
    @IBOutlet weak var highScoreLabel1: UILabel!
    @IBOutlet weak var highScoreLabel2: UILabel!
    @IBOutlet weak var highScoreCountLabel: UILabel!
    
    
    @IBOutlet var tiles: [Tile]!
    
    /// Coordinate system for board.
    /// Origin at top left corner, accessed via [x][y]
    private var grid: [[Tile]] = []
    
    private var bombTiles: [Tile] = []
    
    /// Current Level
    private var level = 1 {
        didSet {
            levelLabel.text = "\(level)"
            shake(levelLabelContainer, vertical: level != 1)
        }
    }
    
    /// Number of bombs currently in board
    private var bombCount = 1 {
        didSet {
            bombLabel.text = "\(bombCount)"
            shake(bombLabel, vertical: bombCount != 1)
            shake(bombImage, vertical: bombCount != 1)
        }
    }
    
    private var highScore = UserDefaults.standard.integer(forKey: "high_score") {
        didSet {
            UserDefaults.standard.set(highScore, forKey: "high_score")
            highScoreCountLabel.text = "\(highScore)"
            shake(highScoreCountLabel, vertical: true)
            shake(highScoreLabel1, vertical: true)
            shake(highScoreLabel2, vertical: true)
        }
    }
    
    /// Game State Enum
    private var state: GameState = .initialized
    
    override func viewDidLoad() {
        super.viewDidLoad()
        highScoreCountLabel.text = "\(highScore)"
        setupButtons()
        generateGrid()
    }
    
    func setupButtons() {
        _ = tiles.map { tile in
            tile.addTarget(self,
                           action: #selector(tileSelected(_:)),
                           for: .touchUpInside)
            tile.layer.cornerRadius = 3
        }
    }
    
    func generateGrid() {
        for x in 0...3 {
            var row: [Tile] = []
            for y in 0...3 {
                let tile = tiles[y * 4 + x]
                tile.x = x
                tile.y = y
                row.append(tile)
            }
            grid.append(row)
            row = []
        }
    }
    
    func buildBoard(exclude selectedTile: Tile) {
        
        guard bombCount > 1 else {
            let exludedTiles = [grid[0][0],
                                grid[0][3],
                                grid[3][0],
                                grid[3][3],
                                ]
            bombTiles = [randomTile(excluding: exludedTiles)]
            return
        }
        
        // Apply bombs
        for _ in 0..<bombCount {
            var excludedTiles = bombTiles
            excludedTiles.append(selectedTile)
            let bombTile = randomTile(excluding: excludedTiles)
            if !bombTiles.contains(bombTile) {
                bombTiles.append(bombTile)
            }
        }
    }
    
    func clearBoard(levelWon: Bool, completion: () -> ()) {
        if levelWon {
            animateNewLevel()
        } else {
            animateTileReset()
        }
        tiles.forEach { $0.cleared = false }
        bombTiles.removeAll()
        completion()
    }
    
    func shake(_ view: UIView, vertical: Bool) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = vertical ? 0.15 : 0.1
        animation.repeatCount = 1
        animation.autoreverses = true
        let from = CGPoint(x: vertical ? view.center.x : view.center.x + 10,
                           y: vertical ? view.center.y + 10 : view.center.y)
        animation.fromValue = NSValue(cgPoint: from)
        let to = CGPoint(x: vertical ? view.center.x : view.center.x - 10,
                         y: vertical ? view.center.y - 10 : view.center.y)
        animation.toValue = NSValue(cgPoint: to)
        view.layer.add(animation, forKey: "position")
    }
    
    func animateNewLevel() {
        // Animate column by column
        for x in 0...3 {
            for y in 0...3  {
                let tile = self.grid[x][y]
                let originalCenter = tile.center
                
                UIView.animate(withDuration: 0.3, delay: 0.1 * Double(x), options: .curveLinear, animations: {
                    tile.frame.origin.x = -100
                    tile.alpha = 0
                }, completion: {
                    complete in
                    
                    // Reset tile position / appearance
                    tile.frame.origin.x = originalCenter.x + 200
                    tile.backgroundColor = UIColor("CDCDCD")
                    tile.setTitle(nil, for: .normal)
                    tile.setImage(nil, for: .normal)
                    
                    let show = {
                        UIView.animate(withDuration: 0.3, delay: 0.05 * Double(x), options: .curveLinear, animations: {
                            tile.center = originalCenter
                            tile.alpha = 1
                            
                        }, completion: nil)
                    }
                    
                    Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: {
                        timer in
                        show()
                    })
                })
            }
        }
    }
    
    func animateTileReset() {
        var animatedTiles: [Tile] = []
        for _ in 1...16 {
            let tile = randomTile(excluding: animatedTiles)
            let originalCenter = tile.center
            
            UIView.animate(withDuration: 0.6,
                           delay: Double(arc4random_uniform(4)) / 10.0,
                           options: .curveLinear,
                           animations: {
                            
                            tile.frame.origin.y = self.view.frame.height + 100
                            let deltaMidX = -(self.view.center.x - tile.convert(tile.center, to: self.view).x)
                            tile.frame.origin.x = tile.frame.origin.x + deltaMidX * 1.4
                            tile.alpha = 0
                            
            }, completion: nil)
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {
                timer in
                
                // Reset tile position / appearance
                tile.center = originalCenter
                tile.backgroundColor = UIColor("CDCDCD")
                tile.setTitle(nil, for: .normal)
                tile.setImage(nil, for: .normal)
                
                // Fade in
                UIView.animate(withDuration: 0.3, animations: {
                    tile.alpha = 1
                })
            })
            animatedTiles.append(tile)
        }
    }
    
    func randomTile(excluding buttons: [Tile]) -> Tile {
        let randomIndex = Int(arc4random_uniform(UInt32(tiles.count)))
        let randomButton = tiles[randomIndex]
        if buttons.contains(randomButton) {
            return randomTile(excluding: buttons)
        }
        return randomButton
    }
    
    /// Changes board accordingly for game state and / or bomb
    func tileSelected(_ tile: Tile) {
        switch state {
        case .initialized:
            // Don't allow bomb on first touch
            buildBoard(exclude: tile)
            state = .inProgress

            analyzeNeighbors(tile)
            checkForLevelCompletion()
            break
        case .inProgress:
            checkForBomb(tile, completion: {
                bombHit in
                
                if !bombHit {
                    self.analyzeNeighbors(tile)
                    self.checkForLevelCompletion()
                } else {
                    self.reset()
                }
            })
            break
        default:
            break
        }
    }
    
    func checkForBomb(_ selectedTile: Tile, completion: @escaping (Bool) -> ()) {
        if bombTiles.contains(selectedTile) {
            bombTiles.forEach { $0.setImage(#imageLiteral(resourceName: "Bomb"), for: .normal) }
            
            UIView.animate(withDuration: 0.2, animations: {
                selectedTile.backgroundColor = UIColor("E76F5D")
            })
            
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {
                timer in
                
                completion(true)
            })
        } else {
            completion(false)
        }
    }
    
    /// Checks to see if level has been won
    func checkForLevelCompletion() {
        if tiles.filter({ !$0.cleared && !self.bombTiles.contains($0) }).isEmpty {
            bombTiles.forEach { $0.setImage(#imageLiteral(resourceName: "Bomb"), for: .normal) }
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {
                timer in
                
                self.advanceLevel()
            })
        }
    }
    
    /// Checks Neighbor tiles and cleares empty spaces
    func analyzeNeighbors(_ selectedTile: Tile) {
        guard !selectedTile.cleared else { return }
        
        selectedTile.backgroundColor = selectedTile.backgroundColor?.darker(by: 10)

        let neighbors = selectedTile.neighbors(grid)
        let bombNeighbors = neighbors.filter { bombTiles.contains($0) }
        
        if bombNeighbors.count > 0 {
            selectedTile.setTitle("\(bombNeighbors.count)", for: .normal)
        } else {
            neighbors.forEach {
                analyzeNeighbors($0)
            }
        }
    }
    
    func advanceLevel() {
        level += 1
        if bombCount < 5 && level % 3 == 0 {
            bombCount += 1
        }
        state = .cleared
        clearBoard(levelWon: true, completion: {
            state = .initialized
        })
        
        if level > highScore {
            highScore = level
        }
    }
    
    func reset() {
        bombCount = 1
        level = 1
        state = .ended
        clearBoard(levelWon: false, completion: {
            state = .initialized
        })
    }
}
