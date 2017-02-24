//
//  Triangle.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation

import Foundation
import Metal
import simd

class Triangle: BaseNode, Node {
    static var vertexType: Vertex.Type = ColoredVertex.self

    convenience init(device: MTLDevice){
        
        let V0 = ColoredVertex(x:  0.0, y:   1.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
        let V1 = ColoredVertex(x: -1.0, y:  -1.0, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
        let V2 = ColoredVertex(x:  1.0, y:  -1.0, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
        
        let verticesArray: [ColoredVertex] = [V0,V1,V2]
        self.init(name: "Triangle", vertices: verticesArray, device: device)
    }
    
    override func buildUniformData(drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4) -> MTLBuffer {
        var nodeModelMatrix = self.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        let uniform = ColoredUniform(modelMatrix: nodeModelMatrix, viewProjectionMatrix: projectionMatrix)
        return self.bufferProvider.nextUniformsBuffer(uniform: uniform)
    }
    
}
