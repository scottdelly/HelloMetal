////
////  Node.swift
////  HelloMetal
////
////  Created by Scott Delly on 2/16/17.
////  Copyright © 2017 ScottDelly. All rights reserved.
////
//
//import Foundation
//import Foundation
//import Metal
//import QuartzCore
//import simd
//
//@objc class Node: NSObject {
//    
//    let name: String
//    var vertexCount: Int
//    var vertexBuffer: MTLBuffer
//    var uniformBuffer: MTLBuffer!
//    var device: MTLDevice
//    
//    var positionX:Float = 0.0
//    var positionY:Float = 0.0
//    var positionZ:Float = 0.0
//    
//    var rotationX:Float = 0.0
//    var rotationY:Float = 0.0
//    var rotationZ:Float = 0.0
//    
//    var scale:Float     = 1.0
//    
//    init(name: String, vertices: [Vertex], device: MTLDevice){
//        // 1
//        var vertexData = [Float]()
//        for vertex in vertices {
//            vertexData += vertex.floatBuffer()
//        }
//        
//        // 2
//        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
//        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
//        
//        // 3
//        self.name = name
//        self.device = device
//        self.vertexCount = vertices.count
//    }
//    
//    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor?) {
//        let renderPassDescriptor = MTLRenderPassDescriptor()
//        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
//        renderPassDescriptor.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
//        
//        let commandBuffer = commandQueue.makeCommandBuffer()
//        
//        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
//        //For now cull mode is used instead of depth buffer
//        renderEncoder.setCullMode(.front)
//        renderEncoder.setRenderPipelineState(pipelineState)
//        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
//        
//        // 1
//        var nodeModelMatrix = self.modelMatrix()
//        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
//        // 2
//        self.uniformBuffer = self.device.makeBuffer(length: MemoryLayout<Float>.size * float4x4.numberOfElements() * 2, options: [])
//        // 3
//        let bufferPointer = self.uniformBuffer.contents()
//        // 4
//        var projectionMatrix = projectionMatrix
//        memcpy(bufferPointer, &nodeModelMatrix, MemoryLayout<Float>.size * float4x4.numberOfElements())
//        memcpy(bufferPointer + MemoryLayout<Float>.size * float4x4.numberOfElements(), &projectionMatrix, MemoryLayout<Float>.size * float4x4.numberOfElements())
//        // 5
//        renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, at: 1)
//        
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: self.vertexCount, instanceCount: self.vertexCount/3)
//        renderEncoder.endEncoding()
//        
//        commandBuffer.present(drawable)
//        commandBuffer.commit()
//    }
//    
//    func modelMatrix() -> float4x4 {
//        var matrix = float4x4()
//        matrix.translate(positionX, y: positionY, z: positionZ)
//        matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
//        matrix.scale(scale, y: scale, z: scale)
//        return matrix
//    }
//    
//}
