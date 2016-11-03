//
//  ScoreView.swift
//  Popper
//
//  Created by Jonah Witcig on 10/25/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import UIKit

import Game

class ScoreView: UIView {
    @IBOutlet weak var yourScoreLabel: UILabel!
    @IBOutlet weak var theirScoreLabel: UILabel!
    
    @IBOutlet weak var winnerLabel: UILabel!
    
    var done: (()->Void)?
    
    var yourScore: String {
        get { return yourScoreLabel.text ?? "" }
        set { yourScoreLabel.text = "score: \(newValue)" }
    }
    var theirScore: String? {
        get { return theirScoreLabel.text }
        set { theirScoreLabel.text = newValue != nil ? "their score: \(newValue!)" : nil }
    }
    
    var winner: Team.OneOnOne? {
        didSet {
            guard let winner = winner else { return }
            
            switch winner {
            case .you:
                winnerLabel.text = "you won!"
            case .them:
                winnerLabel.text = "they won."
            }
        }
    }
    
    static func create() -> ScoreView {
        var view: ScoreView!
        
        view = Bundle.main.loadNibNamed("ScoreView", owner: view, options: nil)!.first! as! ScoreView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    @IBAction func donePressed(sender: Any) {
        removeFromSuperview()
        done?()
    }
}
