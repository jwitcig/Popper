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
    
    let desiredShapeQuantity: Int
    
    let seed: Int
    let randomSource: GKRandomSource
    
    let padding: Padding?
    
    var createShape: ((CGPoint, CGFloat)->Void)?
    
    var createItemTimer: Timer?
    
    let lifeCycle: LifeCycle
    let gameCycle: SessionCycle<Popper>
    
    init(previousSession: Session<Popper>?,
             createShape: @escaping (CGPoint, CGFloat)->Void,
                 padding: Padding?,
                   cycle: LifeCycle,
               gameCycle: SessionCycle<Popper>) {
                
        self.desiredShapeQuantity = previousSession?.initial.desiredShapeQuantity ?? 3
    
        self.seed = previousSession?.initial.seed ?? GKRandomDistribution(lowestValue: 0, highestValue: 10000000).nextInt()
        self.randomSource = GKLinearCongruentialRandomSource(seed: UInt64(seed))
        
        self.padding = padding
        
        self.createShape = createShape
        
        self.lifeCycle = cycle
        self.gameCycle = gameCycle
    }

    func start() {
        lifeCycle.start()
        
        let xLow = padding?.left ?? 0
        let xHigh = Int(UIScreen.size.width) - (padding?.right ?? 0)
        
        let yLow = padding?.top ?? 0
        let yHigh = Int(UIScreen.size.height) - (padding?.bottom ?? 0)

        let spread = RandomPointGenerator(x: (xLow, xHigh), y: (yLow, yHigh), source: randomSource)
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
    var score: Int { return dictionary["instance-score"]!.int! }
    
    init?(dictionary: [String: String]) {
        guard let _ = dictionary["instance-score"]?.int else { return nil }
        self.dictionary = dictionary
    }
}

extension InitialData where SessionType: Popper {
    var seed: Int { return dictionary["instance-seed"]!.int! }
    var desiredShapeQuantity: Int { return dictionary["instance-desiredShapeQuantity"]!.int! }
    
    init?(dictionary: [String: String]) {
        guard let _ = dictionary["instance-seed"]?.int else { return nil }
        guard let _ = dictionary["instance-desiredShapeQuantity"]!.int else { return nil }
        self.dictionary = dictionary
    }
}

public extension StringDictionaryRepresentable {
    init?(reader: Reader) {
        self.init(dictionary: reader.data)
    }
}
