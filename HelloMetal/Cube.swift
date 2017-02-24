//
//  Cube.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import UIKit
import Metal
import simd

class Cube: BaseNode, Node {
    
    static var vertexType: Vertex.Type = ColoredVertex.self
    
    convenience init(device: MTLDevice){
        
        let A = ColoredVertex(x: -1.0, y:   1.0, z:   1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
        let B = ColoredVertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
        let C = ColoredVertex(x:  1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
        let D = ColoredVertex(x:  1.0, y:   1.0, z:   1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0)
        
        let Q = ColoredVertex(x: -1.0, y:   1.0, z:  -1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
        let R = ColoredVertex(x:  1.0, y:   1.0, z:  -1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
        let S = ColoredVertex(x: -1.0, y:  -1.0, z:  -1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
        let T = ColoredVertex(x:  1.0, y:  -1.0, z:  -1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0)
        
        let verticesArray:[ColoredVertex] = [
            A,B,C ,A,C,D,   //Front
            R,T,S ,Q,R,S,   //Back
            
            Q,S,B ,Q,B,A,   //Left
            D,C,T ,D,T,R,   //Right
            
            Q,A,D ,Q,D,R,   //Top
            B,S,T ,B,T,C    //Bot
        ]
        
        self.init(name: "Cube", vertices: verticesArray, device: device)
    }
    
    override func buildUniformData(drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4) -> MTLBuffer {
        var nodeModelMatrix = self.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        let uniform = ColoredUniform(modelMatrix: nodeModelMatrix, viewProjectionMatrix: projectionMatrix)
        return self.bufferProvider.nextUniformsBuffer(uniform: uniform)
    }
    
//    override func update(delta: CFTimeInterval) {
//        
//        super.update(delta: delta)
//        
//        let secsPerMove: Float = 6.0
//        self.rotationY = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
//        self.rotationX = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
//    }
}
