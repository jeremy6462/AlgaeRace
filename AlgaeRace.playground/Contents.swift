//: Playground - noun: a place where people can play

import UIKit

typealias ScreenPercentage = Double

struct Fish {
    
    /// the amount of oxygen the fish currently has (represented as a percentage)
    var oxygenSupply = 1.0
    
    /// the current position of the fish onscreen (represented as a percentage of the horizontal screen points
    var currentPosition: ScreenPercentage = 0.5

}

class FishMover {
    
    enum Direction {
        case right
        case left
    }
    
    private var fish: Fish
    private var currentMovementTimer: Timer?
    
    weak var delegate: FishMovementSubscriber?
    
    init(fish: Fish) {
        self.fish = fish
    }
    
    func move(by distance: ScreenPercentage, every timeAmount: TimeInterval, towards direction: Direction) {
        
        if let existingTimer = self.currentMovementTimer {
            existingTimer.invalidate()
            self.currentMovementTimer = nil
        }
        
        var movement: ScreenPercentage
        
        switch direction {
        case .right:
            movement = distance
        case .left:
            movement = -distance
        }
        
        let movementTimer = Timer(timeInterval: timeAmount, repeats: true) { (timer) in
            self.fish.currentPosition += distance
            self.delegate?.movement(of: self.fish, by: distance, towards: direction)
        }
        
        self.currentMovementTimer = movementTimer
        
        movementTimer.fire()
        
    }
    
    func stopCurrentMovement() {
        self.currentMovementTimer?.invalidate()
        self.currentMovementTimer = nil
    }
    
}

protocol FishMovementSubscriber: class {
    func movement(of fish: Fish, by distance: ScreenPercentage, towards direction: FishMover.Direction)
}


