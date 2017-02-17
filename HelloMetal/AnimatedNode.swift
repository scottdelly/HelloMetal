//
//  AnimatedNode.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation

class AnimatedNode: Node {
    var time:CFTimeInterval = 0.0
    func update(delta: CFTimeInterval){
        self.time += delta
    }
}
