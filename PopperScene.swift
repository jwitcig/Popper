//
//  GameScene.swift
//  Test
//
//  Created by Jonah Witcig on 10/27/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import GameplayKit
import Messages
import SpriteKit

import Game
import iMessageTools
import SwiftTools

infix operator |

fileprivate extension CGPoint {
    func isInItem(_ item: TapItem) -> Bool {
        return item.node.contains(self)
    }
}

class PopperScene: SKScene, GameScene {
    static let SceneName = "PopperScene"
    
    typealias Session = PopperSession
    
    typealias GameType = Popper

    var game: Game!
    var popper: Popper {
        return game as! Popper
    }
    
    let opponentsSession: PopperSession?
    
    private var tapItems = [TapItem]()
    
    let scoreView = ScoreView.create()
    
    private var leftToDisplay = 0 {
        didSet { (leftToDisplay == 0) | popper.stopCreating }
    }
    private var leftToPop = 0 {
        didSet { (leftToPop == 0) | popper.finish }
    }
    
    let gameCycleDelegate: GameCycleDelegate
    
    public required init(initial providedInitial: PopperInitialData?, previousSession: PopperSession?, delegate gameCycleDelegate: GameCycleDelegate) {
        let initial = providedInitial ?? previousSession?.initial ?? PopperInitialData.random()
        
        self.leftToDisplay = initial.desiredShapeQuantity
        self.leftToPop = initial.desiredShapeQuantity
        
        self.opponentsSession = previousSession

        self.gameCycleDelegate = gameCycleDelegate

        super.init(size: UIScreen.size)
        self.scaleMode = .aspectFill
        
        let lifeCycle = SessionCycle(started: nil, finished: finished, generateSession: gatherSessionData)
        
        self.game = Popper(previousSession: previousSession,
                                   initial: initial,
                               createShape: addShape,
                                   padding: Padding(left: 30, right: 30, top: 120, bottom: 80),
                                     cycle: lifeCycle)
    }
    
    func finished(currentSession: PopperSession) {
        showScore(game: popper, yourScore: currentSession.instance.score,
                               theirScore: opponentsSession?.instance.score)
        gameCycleDelegate.finished(session: currentSession)
    }
    
    private func showScore(game: Popper, yourScore: Double, theirScore: Double? = nil) {
        guard let view = view else { return }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        
        guard let yourFormattedScore = numberFormatter.string(from: NSNumber(value: yourScore)) else { return }
        let theirFormattedScore = theirScore == nil ? nil : numberFormatter.string(from: NSNumber(value: theirScore!))
        
        view.addSubview(scoreView)
        
        scoreView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scoreView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        scoreView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scoreView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        
        scoreView.yourScore = yourFormattedScore
        scoreView.theirScore = theirFormattedScore
        scoreView.winner = nil
        if let theirScore = theirScore {
            scoreView.winner = yourScore > theirScore ? .you : .them
        }
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        
    }
    
    func touchDown(atPoint position: CGPoint) {
        tapItems.filter(position.isInItem).forEach(pop)
    }
    
    func pop(_ item: TapItem) {
        leftToPop -= 1
        item.node.removeFromParent()
    }
    
    func touchMoved(toPoint position: CGPoint) {
        
    }
    
    func touchUp(atPoint position: CGPoint) {
        
    }
    
    func addShape(at position: CGPoint, radius: CGFloat) {
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = position
        node.fillColor = .red
        node.strokeColor = .black
        node.lineWidth = 2
        
        let tapItem = TapItem(node: node)
        
        node.setScale(0)
        let scale = SKAction.scale(to: 1, duration: 0.2)
        scale.timingMode = .easeOut
        node.run(scale)
        
        addChild(node)
        tapItems.append(tapItem)
        
        leftToDisplay -= leftToDisplay > 0 ? 1 : 0
    }
    
    func gatherSessionData() -> PopperSession {
        let yourScore: Double = popper.lifeCycle.elapsedTime
        
        var winner: Team.OneOnOne?
        if let theirScore = opponentsSession?.instance.score {
            winner = yourScore < theirScore ? .you : .them
        }
        
        let instance = PopperInstanceData(score: yourScore, winner: winner)
        let initial = PopperInitialData(seed: popper.initial.seed, desiredShapeQuantity: popper.initial.desiredShapeQuantity)
        return PopperSession(instance: instance, initial: initial, messageSession: nil)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
}
