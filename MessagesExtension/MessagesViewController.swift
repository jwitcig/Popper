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
import iMessagePack
import SwiftTools

infix operator |

class MessagesViewController: MSMessagesAppViewController, iMessageCycle {
    fileprivate var gameController: UIViewController?
    
    var isAwaitingResponse = false
    
    var messageCancelled = false

    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        if let message = conversation.selectedMessage {
            handleStarterEvent(message: message, conversation: conversation)
        } else {
            let controller = createGameController(ofType: Popper.self)
            present(controller)
            controller.startNewGame()
        }
    }
    
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        guard message != nil else { return } // potential Xcode bug, message might come thru as nil
        handleStarterEvent(message: message, conversation: conversation)
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        guard let reader = Reader(message: message) else { return }
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
            
            if messageCancelled {
                guard !isAwaitingResponse else {
                    showWaitingForOpponent()
                    return
                }
                
                if let conversation = activeConversation, let message = conversation.selectedMessage {
                    handleStarterEvent(message: message, conversation: conversation)
                } else {
//                    show(gameController, status: .new)
                }
                messageCancelled = false
            }
        }
    }
    
    func handleStarterEvent(message: MSMessage, conversation: MSConversation) {
        guard !MSMessage.isFromCurrentDevice(message: message,
                                        conversation: conversation) else {
            showWaitingForOpponent()
            return
        }
        
        guard let reader = Reader(message: message) else { return }
        
        //  let session = iMSGGameSession<GameType>.parse(reader: reader)
        
        isAwaitingResponse = false
        
        if let controller = gameController {
            throwAway(controller: controller)
        }
        let controller = createGameController(ofType: Popper.self)
        present(controller)
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
    
    fileprivate func createGameController<T: Game>(ofType _: T.Type, fromMessage parser: Reader? = nil) -> GameViewController<T> {
        return GameViewController<T>.create(fromMessage: parser)
    }
}
