//
//  TextRenderer.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/23/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation

class TextRenderer: Renderer<TextNode> {
    override func buildPipeline() -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = super.buildPipeline()
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = self.newVertexDescriptor()
        return pipelineDescriptor
    }
    
    func newVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Texture coordinates
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size*4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stride = MemoryLayout<TextVertex>.size
        
        return vertexDescriptor
    }
}
