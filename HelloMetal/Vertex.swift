//
//  Vertex.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation
struct Vertex {
    
    var x,y,z: Float     // position data
    var r,g,b,a: Float   // color data
    
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a]
    }
    
};
