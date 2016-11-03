//
//  Shape.swift
//  Popper
//
//  Created by Jonah Witcig on 10/25/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import SpriteKit

class TapItem {
    let node: SKNode
    
    var position: CGPoint {
        get { return node.position }
        set { return node.position = newValue }
    }
    
    init(node: SKNode) {
        self.node = node
    }
}
