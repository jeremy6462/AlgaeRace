//: Playground - noun: a place where people can play

import UIKit
import SpriteKit
import PlaygroundSupport

/*
 Game: Algae Race
 Premise: User controls a fish that stays at the bottom of the screen and can move left and right by tapping the right and left sides of the screen. They're goal is to stay alive by collecting oxygen bubbles that gradually and navigate around the ever growing population of algae. The algae should begin competing with the fish (albeit slower, then the fish) to get the oxygen. As the game continues, oxygen become more spares because the algae is overpopulated. The scene gets darker and there's less and less oxygen. Eventually, the fish dies and the hope is that the students compare times with each other for how long they stayed alive.
 Learning Goals:
    - Sun light causes algae to grow
    - Oxygen is necessary for live for the fish
    - Once algae overcome carrying capacity, they begin consuming oxygen and competing with the fish
 
 Oxygen Changes:
    - Goes up: fish touches an oxygen bubble
    - Goes down: small rate of decrease over time, larger rate for each movement
 
 Movement:
    - Move at a certain screen percentage when in normal water
    - Move at slower screen percentage with in algae
 
 Constant increasing rate of algae growth, but when oxygen becomes very sparse, the rate decreases to 0
 */

typealias DecimalPercentage = Double

typealias Probability = DecimalPercentage

struct Fish {
    
    // MARK: Properties
    
    /// the amount of oxygen the fish currently has (represented as a percentage)
    private(set) var oxygenSupply: DecimalPercentage
    
    /// the current position of the fish onscreen (represented as a percentage of the horizontal screen points
    var currentHorizontalPosition: DecimalPercentage
    
    // MARK: Subscribers
    weak var oxygenSubscriber: FishOxygenSupplySubscriber?
    weak var movementSubscriber: FishMovementSubscriber?
    
    // MARK: Rates
    private let OXYGEN_MOVEMENT_COST: DecimalPercentage = 0.02
    
    var isAlive: Bool {
        return oxygenSupply != 0.0
    }
    
    init(oxygenSupply: DecimalPercentage = 1.0, horizontalPosition: DecimalPercentage = 0.5) {
        self.oxygenSupply = oxygenSupply
        self.currentHorizontalPosition = horizontalPosition
    }
    
    mutating func move(by amount: DecimalPercentage) {
        self.currentHorizontalPosition += amount
        self.movementSubscriber?.movement(of: self, to: self.currentHorizontalPosition)
        self.updateOxygenSupply(by: OXYGEN_MOVEMENT_COST)
    }
    
    mutating func updateOxygenSupply(by amount: DecimalPercentage) {
        self.oxygenSupply += amount
        self.oxygenSubscriber?.oxygenSupply(of: self, didUpdateTo: self.oxygenSupply)
    }
    
}

protocol FishOxygenSupplySubscriber: class {
    func oxygenSupply(of fish: Fish, didUpdateTo oxygenSupply: DecimalPercentage)
}

protocol FishMovementSubscriber: class {
    func movement(of fish: Fish, to position: DecimalPercentage)
}

enum RowContainable {
    case algae
    case oxygen
    case water
}

struct Row {
    
    static let CONTENT_UNIT_SIZE: DecimalPercentage = 0.05
    
    var contents = [RowContainable](repeating: .water, count: Int(1.0/Row.CONTENT_UNIT_SIZE))
    
    init(difficulty: Probability) {
        
        var maybeOxygenIndex: Int? = nil
        
        // only one oxygen per row
        let containsOxygen = Double.random >= difficulty
        if containsOxygen {
            let index = Int(arc4random_uniform(UInt32(contents.count)))
            contents[index] = .oxygen
            maybeOxygenIndex = index
        }
        
        // fill rest probablistically with algae
        for index in 0 ..< contents.count {
            if let oxygenIndex = maybeOxygenIndex, index != oxygenIndex {
                continue
            }
            let containsAlgaeClump = Double.random <= pow(difficulty, 2.0) // exponentially gets more likely to be true
            if containsAlgaeClump  {
                contents[index] = .algae
            }
        }
        
    }
    
}

extension Double {
    
    /// returns a random Double between 0 and 1
    static var random: Double {
        return Double(Double(arc4random()) / Double(UINT32_MAX))
    }
}



class AlgaeRaceViewController: UIViewController {
    
    let skView = { () -> SKView in
        let view = SKView(frame: CGRect(x: 0.0, y: 0.0, width: 473.0, height: 627.0))
        view.ignoresSiblingOrder = true
        view.showsFPS = true
        view.showsNodeCount = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = AlgaeRaceScene()
        self.skView.presentScene(scene)
        
        self.view.addSubview(skView)
        NSLayoutConstraint.activate([
            self.skView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.skView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.skView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.skView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            ])
    }
}

class AlgaeRaceScene: SKScene {
    
    let VISIBLE_ROW_COUNT = 10
    
    let fishModel = Fish()
    var fishSprite = { () -> SKSpriteNode in
        let sprite = SKSpriteNode(imageNamed: "fish")
        sprite.size = CGSize(width: 0.1, height: 0.1)
        return sprite
    }()
    
    var currentRows = [(row: Row, nodeGroup: SKNode)]()
    
    var currentDifficulty = 0.5
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = SKColor(displayP3Red: 224/255, green: 238/255, blue: 255/255, alpha: 1.0)
        
        self.fishSprite.position = CGPoint(x: self.size.width * CGFloat(self.fishModel.currentHorizontalPosition), y: fishSprite.size.height)
        self.addChild(self.fishSprite)
        
        for _ in 0..<VISIBLE_ROW_COUNT+1 {
            self.addNewRow()
        }
        
        self.currentRows.map { $0.nodeGroup }.forEach {
            self.addChild($0)
        }
        
        
        
    }
    
    func addNewRow() {
        
        let row = Row(difficulty: self.currentDifficulty)
        
        let group = SKNode()
        
        for position in 0 ..< row.contents.count {
            
            let content = row.contents[position]
            var maybeAssetName: String? = nil
            
            switch content {
            case .algae:
                maybeAssetName = "algae"
            case .oxygen:
                maybeAssetName = "o2_bubble"
            case .water:
                break
            }
            
            guard let assetName = maybeAssetName else {
                continue
            }
            
            let sprite = SKSpriteNode(imageNamed: assetName)
            sprite.size = CGSize(width: Row.CONTENT_UNIT_SIZE, height: Row.CONTENT_UNIT_SIZE)
            sprite.position = CGPoint(x: CGFloat(position)/CGFloat(row.contents.count), y: CGFloat(self.currentRows.count)/CGFloat(VISIBLE_ROW_COUNT))
            
            group.addChild(sprite)
        }
        
        self.currentRows.append((row: row, nodeGroup: group))
    }
    
}

extension AlgaeRaceScene: FishMovementSubscriber, FishOxygenSupplySubscriber {
    
    func movement(of fish: Fish, to position: DecimalPercentage) {
    
    }
    
    func oxygenSupply(of fish: Fish, didUpdateTo oxygenSupply: DecimalPercentage) {
        
    }

}

PlaygroundPage.current.liveView = AlgaeRaceViewController()
