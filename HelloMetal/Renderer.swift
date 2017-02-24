//
//  Renderer.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/21/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation
import MetalKit
import QuartzCore
import simd

class Renderer<T: Node> {
    
    var worldModelMatrix:float4x4!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue
    var projectionMatrix: float4x4
    
    init(device: MTLDevice, aspectRatio: Float) {
        self.worldModelMatrix = float4x4()
        self.worldModelMatrix.translate(0.0, y: 0.0, z: -4)//translate(0.0, y: 0.0, z: -4)
        self.worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 25), y: 0.0, z: 0.0)
        
        self.projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0), aspectRatio: aspectRatio, nearZ: 0.01, farZ: 100.0)
        self.commandQueue = device.makeCommandQueue()

        let pipeline = self.buildPipeline()
        let library = device.newDefaultLibrary()!
        pipeline.vertexFunction = T.vertexFunctionIn(library: library)
        pipeline.fragmentFunction = T.fragmentFunctionIn(library: library)
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipeline)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    func buildPipeline() -> MTLRenderPipelineDescriptor {
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        
        return pipelineStateDescriptor
    }
    
    func render(node: Node, inDrawable drawable: CAMetalDrawable) {
        node.render(self.commandQueue, pipelineState: self.pipelineState, drawable: drawable, parentModelViewMatrix: self.worldModelMatrix, projectionMatrix: self.projectionMatrix, clearColor: nil)
    }
    
}
