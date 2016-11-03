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

final class Popper: SessionedGame {
    typealias GameType = Popper
    
    static let GameName = "Popper"
    
    let desiredShapeQuantity: Int
    
    let seed: Int
    let randomSource: GKRandomSource
    
    let padding: Padding?
    
    var createShape: ((CGPoint, CGFloat)->Void)?
    
    var createItemTimer: Timer?
    
    let lifeCycle: LifeCycle
    let gameCycle: GameCycle<Popper>
    
    init(previousSession: GameSession<Popper>?,
             createShape: @escaping (CGPoint, CGFloat)->Void,
                 padding: Padding?,
                   cycle: LifeCycle,
               gameCycle: GameCycle<Popper>) {
                
        self.desiredShapeQuantity = previousSession?.gameData.desiredShapeQuantity ?? 3
    
        self.seed = previousSession?.gameData.seed ?? GKRandomDistribution(lowestValue: 0, highestValue: 10000000).nextInt()
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

extension GameData: MessageSendable {
    public static func parse(reader: Reader) -> GameData<GameType>? {
        return nil
    }
}

extension GameData where GameType: Popper {
    var score: Double {
        get { return dictionary["score"]!.double! }
        set { dictionary["score"] = newValue.string! }
    }
    var seed: Int {
        get { return dictionary["seed"]!.int! }
        set { dictionary["seed"] = newValue.string! }
    }
    var desiredShapeQuantity: Int {
        get { return dictionary["desiredShapeQuantity"]!.int! }
        set { dictionary["desiredShapeQuantity"] = newValue.string! }
    }
    
    init(score: Double, seed: Int, desiredShapeQuantity: Int) {
        self.dictionary = [
            "score": score.string!,
            "seed": seed.string!,
            "desiredShapeQuantity": desiredShapeQuantity.string!,
        ]
    }
    
    init?(dictionary: [String: String]) {
        guard let _ = dictionary["score"]?.double else { return nil }
        guard let _ = dictionary["seed"]?.int else { return nil }
        guard let _ = dictionary["desiredShapeQuantity"]?.int else { return nil }

        self.dictionary = dictionary
    }
    
    init?(reader: Reader) {
        guard let _ = reader.data["score"]?.double else { return nil }
        guard let _ = reader.data["seed"]?.int else { return nil }
        guard let _ = reader.data["desiredShapeQuantity"]?.int else { return nil }

        self.dictionary = reader.data
    }
}

extension GameInitData where GameType: Popper {
    var seed: Int {
        get { return dictionary["seed"]!.int! }
        set { dictionary["seed"] = newValue.string! }
    }
    var desiredShapeQuantity: Int {
        get { return dictionary["desiredShapeQuantity"]!.int! }
        set { dictionary["desiredShapeQuantity"] = newValue.string! }
    }
    
    static func random() -> GameInitData<Popper> {
        let seed = GKRandomDistribution(lowestValue: 0, highestValue: 10000000).nextInt()
        return GameInitData<Popper>(seed: seed, desiredShapeQuantity: 4)
    }
    
    init(seed: Int, desiredShapeQuantity: Int) {
        self.dictionary = [
            "seed": seed.string!,
            "desiredShapeQuantity": desiredShapeQuantity.string!,
        ]
    }
    
    init?(dictionary: [String: String]) {
        guard let _ = dictionary["seed"]?.int else { return nil }
        guard let _ = dictionary["desiredShapeQuantity"]?.int else { return nil }
        
        self.dictionary = dictionary
    }
    
    init?(reader: Reader) {
        guard let _ = reader.data["seed"]?.int else { return nil }
        guard let _ = reader.data["desiredShapeQuantity"]?.int else { return nil }
        
        self.dictionary = reader.data
    }
}

extension iMSGGameSession: MessageSendable {
    public static func parse(reader: Reader) -> Self? {
        return nil
    }
}

extension iMSGGameSession where T: Popper {
    
    convenience init(gameOver: Bool, gameData: GameData<GameType>, messageSession: MSSession?) {
        self.init(sessionData: ["gameOver": gameOver.string!], gameData: gameData, messageSession: messageSession)
    }
    
    static func parse(reader: Reader) -> iMSGGameSession<Popper>? {
        guard let gameData = GameData<Popper>(dictionary: reader.data) else { return nil }
        
        let sessionData = [
            "gameOver": reader.value(forKey: "gameOver"),
        ]
        
        return iMSGGameSession<Popper>(sessionData: sessionData, gameData: gameData, messageSession: reader.message.session)
    }
}
