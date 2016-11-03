//
//  GameViewController.swift
//  Popper
//
//  Created by Jonah Witcig on 10/27/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import Messages
import SpriteKit
import UIKit

import Game
import iMessageTools
import SwiftTools

protocol SpriteScene {
    var visual: SKScene { get }
}
extension SKScene: SpriteScene {
    var visual: SKScene {
        return self
    }
}

typealias VisualGameScene = GameScene & SpriteScene

class GameViewController<GameType: Game>: MSMessagesAppViewController {
    static var storyboardIdentifier: String { return "GameViewController" }
    
    let scoreView = ScoreView.create()
    
    var opponentsSession: GameSession<GameType>?
    
    var sceneView: SKView! {
        return view as! SKView
    }
    
    var scene: VisualGameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func create(fromMessage parser: Reader? = nil) -> GameViewController<GameType> {
        let controller = GameViewController<GameType>(nibName: GameViewController.storyboardIdentifier, bundle: Bundle(for: GameViewController.self))
        //let session = iMSGGameSession<Popper>.parse(reader: parser)
        if let parser = parser, let initials = GameInitData<Popper>(reader: parser) {
            
        }
        return controller
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func set(initials: GameInitData<GameType>? = nil, opponentSession: iMSGGameSession<GameType>?) {
        self.scene = createScene(ofType: GameType.self, initials: initials, session: opponentSession)
    }
    
    private func setup(scene: SKScene) {
        sceneView.presentScene(scene)
    }
    
    func continueGame(from session: iMSGGameSession<GameType>) {
        
        switch GameType.self {
        case is Popper.Type:
            self.scene = createScene(ofType: GameType.self, session: session)
        default:
            fatalError("unimplemented case")
        }
        
        requestPresentationStyle(.expanded)
        
        let startGameConfirmation = createActionView(action: .startGame)
        startGameConfirmation.action = scene?.game.start
        view.addSubview(startGameConfirmation)
        startGameConfirmation.reapplyConstraints()
    }
    
    func startNewGame() {
        let newGameConfirmation = createActionView(action: .newGame)
        newGameConfirmation.action = {
            self.scene = self.createScene(ofType: GameType.self, session: nil)
            self.requestPresentationStyle(.expanded)
            
            self.setup(scene: self.scene!.visual)
            
            let startGameConfirmation = self.createActionView(action: .startGame)
            startGameConfirmation.action = self.scene?.game.start
            self.view.addSubview(startGameConfirmation)
            startGameConfirmation.reapplyConstraints()
        }
        view.addSubview(newGameConfirmation)
        newGameConfirmation.reapplyConstraints()
    }
    
    private func createActionView(action: GameAction) -> ActionView {
        let actionView = ActionView.create(action: action)
        actionView.centeringConstraints = [
            actionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            actionView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
        ]
        return actionView
    }
    
    func createScene(ofType gameType: GameType.Type, initials: GameInitData<GameType>? = nil, session: iMSGGameSession<GameType>?) -> VisualGameScene {
        
        switch GameType.self {
            
        case is Popper.Type:
            var popperSession: iMSGGameSession<Popper>?
            
            var initials: GameInitData<Popper>!
            if let existing = initials {
                initials = GameInitData<Popper>(dictionary: existing.dictionary)
            }
            initials = initials ?? GameInitData<Popper>.random()
            
            if let session = session, let data = GameData<Popper>(dictionary: session.gameData.dictionary) {
                popperSession = iMSGGameSession<Popper>(sessionData: session.dictionary, gameData: data, messageSession: session.messageSession)
            }
            return PopperScene(initials: initials, previousSession: popperSession)
        default: fatalError()
        }
    }
    
    func started(game: Popper) {
        
    }
    
    func finished(game: Game) {
        
//        if let theirScore = opponentsSession?.data.score {
//            showScore(game: game, yourScore: yourScore, theirScore: theirScore)
//        }
        
        let data = GameData<Popper>(score: 10, seed: 10, desiredShapeQuantity: 4)
        
        let session = iMSGGameSession<Popper>(gameOver: 10 == 90, gameData: data, messageSession: nil)
        
        let message = MessageWriter(data: session.dictionary, session: session.messageSession).message
        
        let layout = MSMessageTemplateLayout()
        layout.caption = "Their turn."
        layout.image = UIImage(named: "image.jpg")

        (parent as? iMessageCycle)?.send(message: message, layout: layout, completionHandler: nil)
        
        scene?.visual.removeFromParent()
        sceneView.presentScene(nil)
    }
    
    private func showScore(game: Popper, yourScore: Double, theirScore: Double? = nil) {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        
        guard let yourFormattedScore = numberFormatter.string(from: NSNumber(value: yourScore)) else { return }
        let theirFormattedScore = theirScore == nil ? nil : numberFormatter.string(from: NSNumber(value: theirScore!))
        
        view.addSubview(scoreView)

        scoreView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scoreView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        scoreView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scoreView.heightAnchor.constraint(equalToConstant: 230).isActive = true
        
        scoreView.yourScore = yourFormattedScore
        scoreView.theirScore = theirFormattedScore
        scoreView.winner = .you
    }
}
