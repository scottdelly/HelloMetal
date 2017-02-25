//
//  TextNode.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/21/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation
import UIKit
import simd

typealias IndexType = UInt16

class TextNode: BaseNode, Node {

    static var vertexType: Vertex.Type = TextVertex.self
    
    static let FontAtlasSize = 2048
    
    var indexBuffer: MTLBuffer!
    var fontTexture: MTLTexture!
    
    override func defaultSampler(_ device: MTLDevice) -> MTLSamplerState {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = .nearest
        sampler.magFilter             = .linear
        sampler.sAddressMode          = .clampToZero
        sampler.tAddressMode          = .clampToZero
        return device.makeSamplerState(descriptor: sampler)
    }
    
    init(string: String, inRect rect: CGRect, withFont font: UIFont, device:MTLDevice) {
        let attributes = [NSFontAttributeName : font]
        let attrString = NSAttributedString(string: string, attributes: attributes)
        let stringRange = CFRangeMake(0, attrString.length)
        let rectPath = CGPath(rect: rect, transform: nil)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let frame = CTFramesetterCreateFrame(framesetter, stringRange, rectPath, nil)
        
        var frameGlyphCount = CFIndex(0)
        let lines = CTFrameGetLines(frame) as! [CTLine]
        
        for i in 0..<lines.count {
            let line = lines[i]
            frameGlyphCount += CTLineGetGlyphCount(line)
        }
        
        let verticesPerGlyph = 4
        let vertexCount = frameGlyphCount * verticesPerGlyph
        let verticesAllocationSize = MemoryLayout<TextVertex>.size * vertexCount
        let vertices = UnsafeMutablePointer<Float>.allocate(capacity: verticesAllocationSize)
        var v = 0

        let indicesPerGlyph = 6
        let indexCount = frameGlyphCount * indicesPerGlyph
        let indicesAllocationSize = MemoryLayout<IndexType>.size * indexCount
        let indices = UnsafeMutablePointer<IndexType>.allocate(capacity: indicesAllocationSize)
        var i = 0
        
        let atlasSize = TextNode.FontAtlasSize
        let fontAtlas = TextNode.makeAtlasFor(font: font, withSize: atlasSize)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: atlasSize, height: atlasSize, mipmapped: false)
        let region = MTLRegionMake2D(0, 0, atlasSize, atlasSize)
        let texture = device.makeTexture(descriptor: textureDescriptor)
        texture.label = "Font Atlas"
        texture.replace(region: region, mipmapLevel: 0, withBytes: (fontAtlas.textureData as NSData).bytes, bytesPerRow: atlasSize)
        
        TextNode.enumerateGlyphs(frame: frame) { (glyph, index, bounds) in
            let glyphDescriptorIndex = Int(glyph)
            if (glyphDescriptorIndex >= fontAtlas.glyphDescriptors.count)
            {
                print("Font atlas has no entry corresponding to glyph \(glyph); Skipping...")
                return
            }
            let glyphInfo = fontAtlas.glyphDescriptors[glyphDescriptorIndex]
            let vertexInfo = [[bounds.minX, bounds.maxY, glyphInfo.topLeftTexCoord.x, glyphInfo.bottomRightTexCoord.y],
                              [bounds.minX, bounds.minY, glyphInfo.topLeftTexCoord.x, glyphInfo.topLeftTexCoord.y],
                              [bounds.maxX, bounds.minY, glyphInfo.bottomRightTexCoord.x, glyphInfo.topLeftTexCoord.y],
                              [bounds.maxX, bounds.maxY, glyphInfo.bottomRightTexCoord.x, glyphInfo.bottomRightTexCoord.y],
                              ]
            for vertexIndex in 0..<verticesPerGlyph {
                let vertex = TextVertex(x: Float(vertexInfo[vertexIndex][0]),
                                           y: Float(vertexInfo[vertexIndex][1]),
                                           z: 0,
                                           textX: Float(vertexInfo[vertexIndex][2]),
                                           textY: Float(vertexInfo[vertexIndex][3]))
                let floatBuffer = vertex.floatBuffer()
                for f in 0..<floatBuffer.count {
                    let index = v*floatBuffer.count+f
                    vertices[index] = floatBuffer[f]
                }
                v += 1
            }
            
            for glyphIndex in 0..<indicesPerGlyph {
                indices[i] = index * 4 + IndexType(glyphIndex)
                i += 1
            }
        }
       
        super.init(name: "Text Node", vertices: vertices, verticesSize: verticesAllocationSize, vertexCount: vertexCount, device: device)

        self.fontTexture = texture
        self.indexBuffer = device.makeBuffer(bytes: indices, length: indicesAllocationSize, options: [])
        self.indexBuffer.label = "Text Mesh Indices"
        self.vertexBuffer.label = "Text Mesh Vertices"
    }
    
    override func createBufferProvider() -> BufferProvider {
        let size = MemoryLayout<TextUniform>.size
        return BufferProvider(device: self.device, inflightBuffersCount: 3, bufferSize: size)
    }

    class func enumerateGlyphs(frame: CTFrame, block: (CGGlyph, IndexType, CGRect) -> ()) {
        let entireRange = CFRangeMake(0, 0)
        
        let framePath = CTFrameGetPath(frame)
        let frameBoundingRect = framePath.boundingBoxOfPath
        
        let lines = CTFrameGetLines(frame) as! [CTLine]
        
        let lineOriginBuffer = UnsafeMutablePointer<CGPoint>.allocate(capacity: lines.count * MemoryLayout<CGPoint>.size)
        CTFrameGetLineOrigins(frame, entireRange, lineOriginBuffer)
        
        var glyphIndexInFrame = IndexType(0)
        
        UIGraphicsBeginImageContext(CGSize(width:1, height:1))
        let context = UIGraphicsGetCurrentContext()
        
        for i in 0..<lines.count {
            let line = lines[i]
            let lineOrigin = lineOriginBuffer[i]
            
            let runs = CTLineGetGlyphRuns(line) as! [CTRun]
            for j in 0..<runs.count {
                var run = runs[j]
                var glyphCount = CTRunGetGlyphCount(run)
                
                var glyphBuffer = UnsafeMutablePointer<CGGlyph>.allocate(capacity: glyphCount * MemoryLayout<CGGlyph>.size)
                CTRunGetGlyphs(run, entireRange, glyphBuffer)
                
                var positionBuffer = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount * MemoryLayout<CGPoint>.size)
                CTRunGetPositions(run, entireRange, positionBuffer)
                
                for g in 0..<glyphCount {
                    var glyph = glyphBuffer[g]
                    var glyphOrigin = positionBuffer[g]
                    var glyphRect = CTRunGetImageBounds(run, context, CFRangeMake(g, 1))
                    var boundsTransX = frameBoundingRect.origin.x + lineOrigin.x
                    var boundsTransY = frameBoundingRect.height + frameBoundingRect.origin.y - lineOrigin.y + glyphOrigin.y
                    var pathTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: boundsTransX, ty: boundsTransY)
                    block(glyph, glyphIndexInFrame, glyphRect.applying(pathTransform));
                    
                    glyphIndexInFrame += 1

                }
            }
        }
        UIGraphicsEndImageContext()
    }
    
    var depthTexture: MTLTexture!
    func buildDepthTexture(forSize size: CGSize) {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        self.depthTexture = self.device.makeTexture(descriptor: descriptor)
        self.depthTexture.label = "Depth Texture"
    }

    override func buildUniformData(drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4) -> MTLBuffer {
        
        let nodeModelMatrix = self.modelMatrix()
        let textColor = float4([0.1,0.1,0.1,0])

        let size = drawable.layer.drawableSize
        let orthoProjectionMatrix = float4x4.makeOrtho(0, Float(size.width), Float(size.height), 0, 0, 1)
        let uniform = TextUniform(modelMatrix: nodeModelMatrix, projectionMatrix: orthoProjectionMatrix, foregroundColor: textColor)
        
        let buffer = self.bufferProvider.nextUniformsBuffer(uniform: uniform)
        return buffer
    }
    
    func renderPass(withColorTexture texture: MTLTexture, depthTexture: MTLTexture) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = texture
        renderPass.colorAttachments[0].loadAction = .clear
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        
        renderPass.depthAttachment.texture = depthTexture
        renderPass.depthAttachment.loadAction = .clear
        renderPass.depthAttachment.storeAction = .store
        renderPass.depthAttachment.clearDepth = 1.0
        return renderPass
    }
    
    override func render(_ commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor?) {
        
        let _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
        let drawableSize = drawable.layer.drawableSize
        
        if self.depthTexture == nil || self.depthTexture.width != Int(drawableSize.width) || self.depthTexture.height != Int(drawableSize.height){
            self.buildDepthTexture(forSize: drawableSize)
        }
        
        let renderPassDescriptor = self.renderPass(withColorTexture: drawable.texture, depthTexture: self.depthTexture)
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer.addCompletedHandler { (commandBuffer) -> Void in
            self.bufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.none)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        let uniformBuffer = self.buildUniformData(drawable: drawable, parentModelViewMatrix: parentModelViewMatrix, projectionMatrix: projectionMatrix)
        
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 0)
        renderEncoder.setFragmentTexture(self.fontTexture, at: 0)
        renderEncoder.setFragmentSamplerState(self.samplerState, at: 0)
        
        let indexCount = self.indexBuffer.length / MemoryLayout<IndexType>.size
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    class func makeAtlasFor(font: UIFont, withSize size: Int) -> MBEFontAtlas {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let atlasName = "\(font.familyName)-\(font.fontName)-\(size)-atlas"
        let atlasURL = URL(string: documentsPath)!.appendingPathComponent(atlasName).appendingPathExtension(".atlas")
        
        let fontAtlas: MBEFontAtlas
        if let atlas = NSKeyedUnarchiver.unarchiveObject(withFile: atlasURL.path) as? MBEFontAtlas {
            fontAtlas = atlas
        } else {
            let atlas = MBEFontAtlas(font: font, textureSize: size)!
            NSKeyedArchiver.archiveRootObject(atlas, toFile: atlasURL.path)
            fontAtlas = atlas
        }
        
        return fontAtlas
    }
    
    override func modelMatrix() -> float4x4 {
        var matrix = float4x4()
        matrix.translate(self.position.x, y: self.position.y, z: 0)
        matrix.scale(self.scale, y: self.scale, z: 1)
        return matrix
    }
    
}
