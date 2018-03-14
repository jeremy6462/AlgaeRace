//: Playground - noun: a place where people can play

import UIKit

typealias ScreenPercentage = Double

struct Fish {
    
    /// the amount of oxygen the fish currently has (represented as a percentage)
    var oxygenSupply = 1.0
    
    /// the current position of the fish onscreen (represented as a percentage of the horizontal screen points
    var currentPosition: ScreenPercentage = 0.5

}

struct FishMover {
    
    let fish: Fish
    
    init(fish: Fish) {
        self.fish = fish
    }
    
    func move(by distance: ScreenPercentage, every second: TimeInterval) {
        
        
        
    }
    
}
