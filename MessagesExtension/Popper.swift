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

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

infix operator |

final class Popper: Game, TypeConstraint, SingleScene {
    typealias Session = PopperSession
    typealias Scene = PopperScene

    static let GameName = "Popper"
    
    typealias SceneType = PopperScene
    
    let initial: PopperInitialData
    
    let padding: Padding?
    
    var createShape: ((CGPoint, CGFloat)->Void)?
    
    var createItemTimer: Timer?
    
    let lifeCycle: LifeCycle
    
    let previousSession: PopperSession?
    
    init(previousSession: PopperSession?,
                 initial: PopperInitialData?,
             createShape: @escaping (CGPoint, CGFloat)->Void,
                 padding: Padding?,
                   cycle: LifeCycle) {
        
        self.initial = initial ?? PopperInitialData.random()
        
        self.padding = padding
        
        self.createShape = createShape
        
        self.lifeCycle = cycle
        
        self.previousSession = previousSession
    }

    func start() {
        lifeCycle.start()
        
        let xLow = padding?.left ?? 0
        let xHigh = Int(UIScreen.size.width) - (padding?.right ?? 0)
        
        let yLow = padding?.bottom ?? 0
        let yHigh = Int(UIScreen.size.height) - (padding?.top ?? 0)
        
        let spread = RandomPointGenerator(x: (xLow, xHigh), y: (yLow, yHigh), source: initial.randomSource)
        
        var previousPoints = [CGPoint]()
        createItemTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
        
            func point(_ point: CGPoint, tooNearTo recentPoints: ArraySlice<CGPoint>) -> Bool {
                return recentPoints.reduce(false) {
                    $0 ? $0 : point.distance(to: $1) < 30
                }
            }
            
            var newPoint: CGPoint!
            var tooNear = true
            while tooNear {
                newPoint = spread.newPoint()
                tooNear = point(newPoint, tooNearTo: previousPoints.suffix(10))
            }
            previousPoints.append(newPoint)
            self.createShape?(newPoint, 25)
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

extension SessionType {
    typealias Key = String
    typealias Value = String
}

struct PopperSession: SessionType, StringDictionaryRepresentable, Messageable {
    typealias Constraint = Popper
    typealias InitialData = PopperInitialData
    typealias InstanceData = PopperInstanceData
    typealias MessageWriterType = PopperMessageWriter
    typealias MessageLayoutBuilderType = PopperMessageLayoutBuilder
    
    typealias Scene = PopperScene
    
    let initial: InitialData
    let instance: InstanceData
    
    let messageSession: MSSession?
    
    var dictionary: [String : String] {
        return instance.dictionary.merged(initial.dictionary)
    }
    
    public init(instance: PopperInstanceData, initial: PopperInitialData, messageSession: MSSession?) {
        self.instance = instance
        self.initial = initial
       
        self.messageSession = messageSession
    }
    
    public init?(dictionary: [String: String]) {
        guard let instance = PopperInstanceData(dictionary: dictionary) else { return nil }
        guard let initial = PopperInitialData(dictionary: dictionary) else { return nil }
        
        self.instance = instance
        self.initial = initial
        
        self.messageSession = nil
    }
}

extension PopperSession {
    var gameData: PopperInstanceData {
        return instance
    }
}

struct PopperInstanceData: InstanceDataType, StringDictionaryRepresentable {
    typealias Constraint = Popper

    let score: Double
    let winner: Team.OneOnOne?
    
    var dictionary: [String: String] {
        return [
            "instance-score": score.string!,
            "instance-winner": winner?.rawValue ?? "incomplete",
        ]
    }
    
    init(score: Double, winner: Team.OneOnOne?) {
        self.score = score
        self.winner = winner
    }
    
    init?(dictionary: [String: String]) {
        guard let score = dictionary["instance-score"]?.double else { return nil }
        guard let winner = dictionary["instance-winner"] else { return nil }
        self.init(score: score, winner: Team.OneOnOne(rawValue: winner))
    }
}

struct PopperInitialData: InitialDataType, StringDictionaryRepresentable {
    typealias Constraint = Popper

    let seed: Int
    let desiredShapeQuantity: Int
    
    var randomSource: GKRandomSource {
        return GKLinearCongruentialRandomSource(seed: UInt64(seed))
    }
    
    var dictionary: [String: String] {
        return [
            "initial-seed": seed.string!,
            "initial-desiredShapeQuantity": desiredShapeQuantity.string!,
        ]
    }
    
    init(seed: Int, desiredShapeQuantity: Int) {
        self.seed = seed
        self.desiredShapeQuantity = desiredShapeQuantity
    }
    
    init?(dictionary: [String: String]) {
        guard let seed = dictionary["initial-seed"]?.int else { return nil }
        guard let desiredShapeQuantity = dictionary["initial-desiredShapeQuantity"]!.int else { return nil }
        self.init(seed: seed, desiredShapeQuantity: desiredShapeQuantity)
    }
    
    static func random() -> PopperInitialData {
        let seed = GKRandomDistribution(lowestValue: 1, highestValue: 1000000000).nextInt()
        return PopperInitialData(seed: seed, desiredShapeQuantity: 10)
    }
}

struct PopperMessageReader: MessageReader, SessionSpecific {
    typealias SessionConstraint = PopperSession
    
    var message: MSMessage
    var data: [String: String]
    
    var session: SessionConstraint!
    
    init() {
        self.message = MSMessage()
        self.data = [:]
    }
    
    mutating func isValid(data: [String : String]) -> Bool {
        guard let instance = PopperInstanceData(dictionary: data) else { return false }
        guard let initial = PopperInitialData(dictionary: data) else { return false }
        self.session = PopperSession(instance: instance, initial: initial, messageSession: message.session)
        return true
    }
}

struct PopperMessageWriter: MessageWriter {
    var message: MSMessage
    var data: [String: String]
    
    init() {
        self.message = MSMessage()
        self.data = [:]
    }
    
    func isValid(data: [String : String]) -> Bool {
        guard let _ = data["initial-seed"]?.int else { return false }
        guard let _ = data["initial-desiredShapeQuantity"]?.int else { return false }
        guard let _ = data["instance-score"]?.double else { return false }
        guard let _ = data["instance-winner"] else { return false }
        return true
    }
}

struct PopperMessageLayoutBuilder: MessageLayoutBuilder {
    let session: PopperSession
    
    init(session: PopperSession) {
        self.session = session
    }
    
    func generateLayout() -> MSMessageTemplateLayout {
        let layout = MSMessageTemplateLayout()
        layout.image = UIImage(named: "image.jpg")
        layout.caption = "Your turn."
        if let winner = session.instance.winner {
            layout.caption = winner == .you ? "You won!" : "You Lost!"
        }
        return layout
    }
    
}
