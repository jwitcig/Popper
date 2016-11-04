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

protocol GameCycleDelegate {
    func started(game: Game)
    func finished<GameType>(session: Session<GameType>)
}

class GameViewController<T>: MSMessagesAppViewController, GameCycleDelegate {
    static var storyboardIdentifier: String { return "GameViewController" }
    
    typealias GameType = T
    
    var messageSender: MessageSender!
    
    let scoreView = ScoreView.create()
    
    var opponentsSession: Session<GameType>?
    
    var sceneView: SKView! {
        return view as! SKView
    }
    
    var scene: GameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func create(fromMessage parser: Reader? = nil, messageSender: MessageSender) -> GameViewController<GameType> {
        let controller = GameViewController<GameType>(nibName: GameViewController.storyboardIdentifier, bundle: Bundle(for: GameViewController.self), messageSender: messageSender)

        if let parser = parser, let _ = InitialData<Popper>.create(dictionary: parser.data) {
            
        }
        return controller
    }
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, messageSender: MessageSender) {
        self.messageSender = messageSender
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func set(initials: InitialData<GameType>? = nil, opponentSession: Session<GameType>?) {
        self.scene = createScene(ofType: GameType.self, initials: initials, session: opponentSession)
    }
    
    private func setup(scene: SKScene) {
        sceneView.presentScene(scene)
    }
    
    func continueGame(from session: Session<GameType>) {
        switch GameType.self {
        case is Popper.Type:
            self.scene = createScene(ofType: GameType.self, initials: nil, session: session)
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
            self.scene = self.createScene(ofType: GameType.self, initials: nil, session: nil)
            self.requestPresentationStyle(.expanded)
            
            self.setup(scene: self.scene as! SKScene)
            
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
    
    func createScene(ofType gameType: GameType.Type, initials existingInitials: InitialData<GameType>?, session previousSession: Session<GameType>?) -> GameScene {
        
        switch GameType.self {
            
        case is Popper.Type:
            var initials: InitialData<Popper>?
            if let existing = existingInitials {
                initials = InitialData<Popper>.create(dictionary: existing.dictionary)
            }
            
            var popperSession: Session<Popper>?
            if let previous = previousSession {
                popperSession = Session<Popper>.init(dictionary: previous.dictionary)
            }
            return PopperScene(initial: initials, previousSession: popperSession, delegate: self, messageSender: messageSender)
        default: fatalError()
        }
    }
    
    func started(game: Game) {
        
    }
    
    func finished<GameType>(session: Session<GameType>) {
        
//        if let theirScore = opponentsSession?.data.score {
//            showScore(game: game, yourScore: yourScore, theirScore: theirScore)
//        }
        
        (scene as? SKScene)?.removeFromParent()
        sceneView?.presentScene(nil)
        
        let layout = MSMessageTemplateLayout()
        layout.caption = "Their turn."
        layout.image = UIImage(named: "image.jpg")
        
        let message = MessageWriter(data: session.dictionary, session: session.messageSession).message
        messageSender.send(message: message, layout: layout, completionHandler: nil)
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
