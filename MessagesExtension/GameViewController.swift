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
    func finished<S>(session: S) where S: SessionType & StringDictionaryRepresentable & Messageable
}

class GameViewController<G>: MSMessagesAppViewController, GameCycleDelegate where G: SessionConstraint, G.Session.ConstraintType == G, G.Session: StringDictionaryRepresentable, G.Session: Messageable, G.Session.InitialData: StringDictionaryRepresentable, G.Session.InstanceData: StringDictionaryRepresentable {
    
    static var storyboardIdentifier: String { return "GameViewController" }
    
    typealias GameType = G
    typealias Session = G.Session
    typealias InitialData = Session.InitialData

    var messageSender: MessageSender?
    var orientationManager: OrientationManager?
    
    let scoreView = ScoreView.create()
    
    var opponentsSession: Session?
    
    var messageSession: MSSession?
    
    var sceneView: SKView! {
        return view as! SKView
    }
    
    var scene: GameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
//    static func create(fromMessage parser: Reader? = nil, messageSender: MessageSender) -> GameViewController<GameType> {
//        let controller = GameViewController<GameType>(messageSender: messageSender)
//
//        if let parser = parser {
//            
//        }
//        return controller
//    }
    
    init(fromMessage parser: MessageReader? = nil, messageSender: MessageSender, orientationManager: OrientationManager) {
        self.messageSession = parser?.message.session
        
        self.messageSender = messageSender
        self.orientationManager = orientationManager
        super.init(nibName: GameViewController.storyboardIdentifier, bundle: Bundle(for: GameViewController.self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
//    func set(initials: InitialDataType? = nil, opponentSession: AnySession) {
//        self.scene = createScene(ofType: GameType.self, initials: initials, session: opponentSession)
//    }
    
    private func setup(scene: SKScene) {
        sceneView.presentScene(scene)
    }
    
    func continueGame(from session: Session) {
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
    
    func createScene(ofType gameType: GameType.Type, initials existingInitials: InitialData?, session previousSession: Session?) -> GameScene {
        switch GameType.self {
            
        case is Popper.Type:
            let initial = existingInitials != nil ? PopperInitialData(dictionary: existingInitials!.dictionary) : nil
            
            let popperSession = previousSession != nil ? PopperSession(dictionary: previousSession!.dictionary) : nil
            
            return PopperScene(initial: initial,
                       previousSession: popperSession,
                              delegate: self)
                default: fatalError()
        }
    }
     
    func started(game: Game) {
        
    }
    
    func finished<S>(session: S) where S: SessionType & StringDictionaryRepresentable & Messageable {
    
//        if let theirScore = opponentsSession?.data.score {
//            showScore(game: game, yourScore: yourScore, theirScore: theirScore)
//        }
        
        (scene as? SKScene)?.removeFromParent()
        sceneView?.presentScene(nil)
        
        let layout = MSMessageTemplateLayout()
        layout.caption = "Their turn."
        layout.image = UIImage(named: "image.jpg")
    
        if let message = S.MessageWriterType(data: session.dictionary, session: messageSession)?.message {
            messageSender?.send(message: message, layout: layout, completionHandler:nil)
        }
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
