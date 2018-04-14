//: Playground - noun: a place where people can play

import UIKit

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

protocol RowContainable { }
struct Algae: RowContainable { }
struct Oxygen: RowContainable { }
struct Water: RowContainable { }

struct Row {
    
    static let CONTENT_UNIT_SIZE: DecimalPercentage = 0.05
    
    var contents = [RowContainable](repeating: Water(), count: Int(1.0/Row.CONTENT_UNIT_SIZE))
    
    init(difficulty: Probability) {
        self.fillRow()
    }
    
    private func fillRow() {
        
        var maybeOxygenIndex: Int? = nil
        
        // only one oxygen per row
        let containsOxygen = Double.random >= difficulty
        if containsOxygen {
            let index = Int(arc4random_uniform(UInt32(contents.count)))
            contents[index] = Oxygen()
            maybeOxygenIndex = index
        }
        
        // fill rest probablistically with algae
        for index in 0 ..< contents.count {
            if let oxygenIndex = maybeOxygenIndex, index != oxygenIndex {
                continue
            }
            var containsAlgaeClump = Double.random <= pow(difficulty, 2.0) // exponentially gets more likely to be true
            if containsAlgaeClump  {
                contents[index] = Algae()
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
