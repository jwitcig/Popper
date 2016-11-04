//
//  Popper.swift
//  Popper
//
//  Created by Jonah Witcig on 10/26/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import GameplayKit
import Messages
import UIKit

import Game
import iMessageTools
import SwiftTools

infix operator |

final class Popper: Game {
    typealias GameType = Popper
    
    static let GameName = "Popper"
    
    let initial: InitialData<Popper>
    
    let padding: Padding?
    
    var createShape: ((CGPoint, CGFloat)->Void)?
    
    var createItemTimer: Timer?
    
    let lifeCycle: LifeCycle
    
    init(previousSession: Session<Popper>?,
                 initial: InitialData<Popper>?,
             createShape: @escaping (CGPoint, CGFloat)->Void,
                 padding: Padding?,
                   cycle: LifeCycle) {
        
        self.initial = initial ?? InitialData<Popper>.random()
        
        self.padding = padding
        
        self.createShape = createShape
        
        self.lifeCycle = cycle
    }

    func start() {
        lifeCycle.start()
        
        let xLow = padding?.left ?? 0
        let xHigh = Int(UIScreen.size.width) - (padding?.right ?? 0)
        
        let yLow = padding?.top ?? 0
        let yHigh = Int(UIScreen.size.height) - (padding?.bottom ?? 0)
        
        let spread = RandomPointGenerator(x: (xLow, xHigh), y: (yLow, yHigh), source: initial.randomSource)
        createItemTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.createShape?(spread.newPoint(), 50)
        }
    }
    
    func finish() {
        lifeCycle.finish()
    }
    
    func stopCreating() {
        createItemTimer?.invalidate()
        createItemTimer = nil
    }
    
    enum MessageKey: String {
        enum Game: String {
            case score, seed, desiredShapesQuantity, gameOver
        }
        case gameName = "Popper"
    }
}

extension Session where SessionType: Popper {
    var gameData: InstanceData<SessionType> {
        return instance
    }
}

extension InstanceData where SessionType: Popper {
    var score: Double { return dictionary["instance-score"]!.double! }
    
    private init(dictionary: [String: String]) {
        self.dictionary = dictionary
    }
    
    static func create(dictionary: [String: String]) -> InstanceData<Popper>? {
        guard let _ = dictionary["instance-score"]?.double else { return nil }
        return InstanceData<Popper>(dictionary: dictionary)
    }
    
    static func create(score: Double) -> InstanceData<Popper> {
        return InstanceData<Popper>(dictionary: [
            "instance-score": score.string!,
        ])
    }
}

extension InitialData where SessionType: Popper {
    var seed: Int { return dictionary["initial-seed"]!.int! }
    var desiredShapeQuantity: Int { return dictionary["initial-desiredShapeQuantity"]!.int! }
    
    var randomSource: GKRandomSource {
        return GKLinearCongruentialRandomSource(seed: UInt64(typed(as: Popper.self).seed))
    }
    
    private init(dictionary: [String: String]) {
        self.dictionary = dictionary
    }
    
    static func create(dictionary: [String: String]) -> InitialData<Popper>? {
        guard let _ = dictionary["initial-seed"]?.int else { return nil }
        guard let _ = dictionary["initial-desiredShapeQuantity"]!.int else { return nil }
        return InitialData<Popper>(dictionary: dictionary)
    }
    
    static func create(seed: Int, desiredShapedQuantity: Int) -> InitialData<Popper> {
        return InitialData<Popper>(dictionary: [
            "initial-seed": seed.string!,
            "initial-desiredShapeQuantity": desiredShapedQuantity.string!,
        ])
    }
    
    static func random() -> InitialData<Popper> {
        let seed = GKRandomDistribution(lowestValue: 1, highestValue: 1000000000).nextInt()
        return InitialData<Popper>.create(seed: seed, desiredShapedQuantity: 3)
    }
}

