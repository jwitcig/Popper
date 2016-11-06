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
    
    typealias GameType = Popper

    var game: Game!
    var popper: Popper {
        return game as! Popper
    }
    
    private var tapItems = [TapItem]()
    
    private var leftToDisplay = 0 {
        didSet { (leftToDisplay == 0) | popper.stopCreating }
    }
    private var leftToPop = 0 {
        didSet { (leftToPop == 0) | popper.finish }
    }
        
    init(initial providedInitial: PopperInitialData?, previousSession: PopperSession?, delegate: GameCycleDelegate) {
        let initial = providedInitial ?? previousSession?.initial ?? PopperInitialData.random()
        
        self.leftToDisplay = initial.desiredShapeQuantity
        self.leftToPop = initial.desiredShapeQuantity
        
        super.init(size: UIScreen.size)
        self.scaleMode = .aspectFill
        
        let lifeCycle = SessionCycle(started: nil, finished: delegate.finished, generateSession: gatherSessionData)
        
        self.game = Popper(previousSession: previousSession,
                                   initial: initial,
                               createShape: addShape,
                                   padding: Padding(left: 10, right: 60, top: 100, bottom: 90),
                                     cycle: lifeCycle)
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
        let score: Double = popper.lifeCycle.elapsedTime
        
        let instance = PopperInstanceData(score: score)
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
