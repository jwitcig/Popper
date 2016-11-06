//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Jonah Witcig on 10/25/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import GameplayKit
import Messages
import UIKit

import Game
import iMessageTools
import SwiftTools

infix operator |

class MessagesViewController: MSMessagesAppViewController, MessageSender {
    fileprivate var gameController: UIViewController?
    
    var isAwaitingResponse = false
    
    var messageCancelled = false
        
    override func willBecomeActive(with conversation: MSConversation) {
        if let message = conversation.selectedMessage {
            handleStarterEvent(message: message, conversation: conversation)
        } else {
            let controller = createGameController(ofType: Popper.self, type: PopperScene.self, other: PopperSession.self)
            present(controller)
            controller.initiateGame()
        }
    }
    
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        guard message != nil else { return } // potential Xcode bug, message might come thru as nil
        handleStarterEvent(message: message, conversation: conversation)
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {

    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        isAwaitingResponse = false
        messageCancelled = true
        if let controller = gameController {
            throwAway(controller: controller)
        }
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        switch presentationStyle {
        case .compact:
            break
        case .expanded:
            break
        }
    }
    
    func handleStarterEvent(message: MSMessage, conversation: MSConversation) {
        guard !MSMessage.isFromCurrentDevice(message: message,
                                        conversation: conversation) else {
            showWaitingForOpponent()
            return
        }
        
        isAwaitingResponse = false
        
        let parser = GeneralMessageReader(message: message)
        
        if let controller = gameController {
            throwAway(controller: controller)
        }
        let controller = createGameController(ofType: Popper.self, type: PopperScene.self, other: PopperSession.self, fromMessage: parser)
        present(controller)
        controller.initiateGame()
    }
}

extension MessagesViewController {
    func createActionView(action: GameAction? = nil) -> ActionView {
        let actionView = ActionView.create(action: action)
        actionView.centeringConstraints = [
            actionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            actionView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
        ]
        return actionView
    }
    
    fileprivate func showWaitingForOpponent() {
        let actionView = createActionView()
        actionView.buttonText = "Waiting For Opponent"
        if let font = actionView.button.titleLabel?.font {
            actionView.button.titleLabel?.font = UIFont(name: font.fontName, size: 30)
        }
        actionView.isUserInteractionEnabled = false
        view.addSubview(actionView)
        actionView.reapplyConstraints()
    }
    
    fileprivate func createGameController<G, S, U>(ofType _: G.Type,
                                          type: S.Type,
                                          other: U.Type,
                                        fromMessage parser: MessageReader? = nil)
        -> GameViewController<G, S, U> where
        G: TypeConstraint,
        U: SessionType & StringDictionaryRepresentable & Messageable,
        U.InitialData: StringDictionaryRepresentable,
        U.InstanceData: StringDictionaryRepresentable,
        G: SingleScene,
        S: SKScene,
        S: GameScene {
        return GameViewController<G, S, U>(fromMessage: parser, messageSender: self, orientationManager: self)
    }
}
