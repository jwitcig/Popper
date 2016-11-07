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

class GameViewController<GameType, Scene, Session>: MSMessagesAppViewController where
    GameType: TypeConstraint & SingleScene,
    Session: SessionType & StringDictionaryRepresentable & Messageable,
    Session.InitialData: StringDictionaryRepresentable,
    Session.InstanceData: StringDictionaryRepresentable,
    Scene: SKScene,
    Scene: GameScene {
   
    static var storyboardIdentifier: String { return "GameViewController" }
    
    typealias InitialData = Session.InitialData
    
    var messageSender: MessageSender!
    var orientationManager: OrientationManager!
        
    var opponentsSession: Session?
    
    var messageSession: MSSession?
    
    var sceneView: SKView! {
        return view as! SKView
    }
    
    var scene: Scene?
    
    init(fromMessage parser: MessageReader? = nil, messageSender: MessageSender, orientationManager: OrientationManager) {
        self.messageSession = parser?.message.session
        
        if let data = parser?.data {
            self.opponentsSession = Session.init(dictionary: data)
        }
        
        self.messageSender = messageSender
        self.orientationManager = orientationManager
        super.init(nibName: GameViewController.storyboardIdentifier, bundle: Bundle(for: GameViewController.self))
        
        setBackgroundColor(color: .black)
    }
    
    private func setBackgroundColor(color: UIColor) {
        let blackScene = SKScene()
        blackScene.backgroundColor = color
        present(scene: blackScene)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func present(scene: SKScene) {
        sceneView.presentScene(scene)
    }
    
    func initiateGame() {
        if let previousSession = opponentsSession {
            continueGame(from: previousSession)
        } else {
            startNewGame()
        }
    }
    
    func continueGame(from session: Session) {
        switch GameType.self {
        case is Popper.Type:
            self.scene = createScene(ofType: GameType.self, initials: session.initial, session: session)
        default:
            fatalError("unimplemented case")
        }
        
        requestPresentationStyle(.expanded)
        
        present(scene: scene!)
        
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
            
            self.present(scene: self.scene!)
            
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
    
    func createScene(ofType gameType: GameType.Type, initials existingInitials: InitialData?, session previousSession: Session?) -> Scene {
        
        switch GameType.self {
            
        case is Popper.Type:
            return PopperScene(initial: existingInitials as? PopperInitialData,
                       previousSession: previousSession as? PopperSession,
                              delegate: self,
                          viewAttacher: self) as! Scene
        default: fatalError()
        }
    }
}

// for game scene to use to get full screen size
extension GameViewController: ViewAttachable {
    func display(view: UIView) {
        guard let mainView = self.view else { return }
        
        mainView.addSubview(view)
        
        view.widthAnchor.constraint(equalTo: mainView.widthAnchor).isActive = true
        view.centerXAnchor.constraint(equalTo: mainView.centerXAnchor).isActive = true
        view.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
    }
}


extension GameViewController: GameCycleDelegate {
    func started(game: Game) {
        
    }
    
    func finished<S>(session: S) where S: SessionType & StringDictionaryRepresentable {
        scene?.removeFromParent()
        sceneView?.presentScene(nil)
        
        orientationManager.requestPresentationStyle(.compact)
        
        var layout = MSMessageTemplateLayout()
        if let popperSession = session as? PopperSession {
            layout = PopperMessageLayoutBuilder(session: popperSession).generateLayout()
        }
        
        if let message = Session.MessageWriterType(data: session.dictionary, session: messageSession)?.message {
            messageSender.send(message: message, layout: layout, completionHandler: nil)
        }
    }
}
