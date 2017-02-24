//
//  Vertex.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation
import Metal
import simd

protocol Vertex {
    static var shaderName: String {get}
    static var fragmentFunctionName: String {get}
    var position: Position { get set }
    func floatBuffer() -> [Float]
}

protocol Uniform {
    func fillBuffer(buffer: MTLBuffer)
}

struct TexturedVertex: Vertex {
    
    internal static var shaderName = "textured_vertex"
    internal static var fragmentFunctionName = "textured_fragment"

    var position: Position
    var r,g,b,a: Float   // color data
    var s,t: Float       // texture coordinates
    var nX,nY,nZ: Float  // normal
    
    func floatBuffer() -> [Float] {
        return [position.x,position.y,position.z,position.w,r,g,b,a,s,t,nX,nY,nZ]
    }
    
    init(x: Float, y: Float, z: Float, r: Float = 0, g: Float = 0, b: Float = 0, a: Float = 1.0, s: Float, t: Float, nX: Float, nY: Float, nZ: Float) {
        self.position = Position([x,y,z,1])
        
        self.r = r
        self.g = g
        self.b = b
        self.a = a
        
        self.s = s
        self.t = t
        
        self.nX = nX
        self.nY = nY
        self.nZ = nZ
    }
}

struct TexturedUniform: Uniform {
    var modelMatrix: float4x4
    var projectionMatrix : float4x4
    var light: Light
    
    static let modelSize = MemoryLayout<Float>.size*float4x4.numberOfElements()
    static let projectionSize = MemoryLayout<Float>.size*float4x4.numberOfElements()
    
    func fillBuffer(buffer: MTLBuffer) {
        let bufferPointer = buffer.contents()
        
        // 1
        var projectionMatrix = self.projectionMatrix
        var modelViewMatrix = self.modelMatrix
        
        // 2
        memcpy(bufferPointer, &modelViewMatrix, TexturedUniform.modelSize)
        memcpy(bufferPointer + TexturedUniform.modelSize, &projectionMatrix, TexturedUniform.projectionSize)
        memcpy(bufferPointer + TexturedUniform.modelSize + TexturedUniform.projectionSize, self.light.raw(), Light.size())
    }
}

struct ColoredVertex: Vertex {
    
    internal static var shaderName = "colored_vertex"
    internal static var fragmentFunctionName = "colored_fragment"

    var position: Position
    var r,g,b,a: Float   // color data
    
    func floatBuffer() -> [Float] {
        return [position.x,position.y,position.z,position.w,r,g,b,a]
    }
    
    init(x: Float, y: Float, z: Float, r: Float = 0, g: Float = 0, b: Float = 0, a: Float = 1.0) {
        self.position = Position([x,y,z,0])
        
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
}

struct ColoredUniform: Uniform {
    var modelMatrix: float4x4
    var viewProjectionMatrix : float4x4
    
    func fillBuffer(buffer: MTLBuffer) {
        //
    }
}

struct TextVertex: Vertex {
    
    internal static var shaderName = "text_vertex"
    internal static var fragmentFunctionName = "text_fragment"

    var position: Position
//    var r,g,b,a: Float   // color data
    let textPosition: packed_float2
    
    func floatBuffer() -> [Float] {
        return [position.x,position.y,position.z,position.w,textPosition.x,textPosition.y]//,r,g,b,a]
    }
    
    init(x: Float, y: Float, z: Float, textX: Float, textY: Float, r: Float = 0, g: Float = 0, b: Float = 0, a: Float = 1.0) {
        self.position = Position([x,y,z,1])
       
//        self.r = r
//        self.g = g
//        self.b = b
//        self.a = a
        
        self.textPosition = packed_float2([textX, textY])
        
    }
}

struct TextUniform: Uniform {
    var modelMatrix: float4x4
    var projectionMatrix : float4x4
    var foregroundColor: float4
    
    let modelSize = MemoryLayout<float4x4>.size
    let projectionSize = MemoryLayout<float4x4>.size
    let foregroundColorSize = MemoryLayout<float4>.size
    
    func fillBuffer(buffer: MTLBuffer) {
        let bufferPointer = buffer.contents()
        
        // 1
        var projectionMatrix = self.projectionMatrix
        var modelViewMatrix = self.modelMatrix
        var foregroundColor = self.foregroundColor
        // 2
        memcpy(bufferPointer, &modelViewMatrix, self.modelSize)
        memcpy(bufferPointer + self.modelSize, &projectionMatrix, self.projectionSize)
        memcpy(bufferPointer + self.modelSize + self.projectionSize, &foregroundColor, self.foregroundColorSize)
    }
}
