//
//  Node.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import Foundation
import Metal
import QuartzCore
import simd

typealias Position = packed_float4

protocol Node: class {
    static var vertexType: Vertex.Type { get }
    
    var position: Position {get set}
    var rotation: Position {get set}
    var scale: Float {get set}
    var bufferProvider: BufferProvider! {get set}

    func render(_ commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor?)
    static func vertexFunctionIn(library: MTLLibrary) -> MTLFunction
    static func fragmentFunctionIn(library: MTLLibrary) -> MTLFunction
}

extension Node {
    
    static func vertexFunctionIn(library: MTLLibrary) -> MTLFunction {
        return library.makeFunction(name: "\(Self.vertexType.shaderName)")!
    }
    
    static func fragmentFunctionIn(library: MTLLibrary) -> MTLFunction {
        return library.makeFunction(name: "\(Self.vertexType.fragmentFunctionName)")!
    }
}

protocol AnimatedNode: Node {
    var time: CFTimeInterval {get set}
}

extension AnimatedNode {
    func updateWithDelta(_ delta: CFTimeInterval) {
        self.time += delta
    }
}

class BaseNode {

    var time:CFTimeInterval = 0.0

    var name: String
    var device: MTLDevice
    var vertexCount: Int = 0
    var texture: MTLTexture?
    var vertexBuffer: MTLBuffer
    lazy var bufferProvider: BufferProvider! = self.createBufferProvider()
    
    var position = Position([0,0,0,0])
    var rotation = Position([0,0,0,0])
    var scale: Float = 1.0

    
    lazy var samplerState: MTLSamplerState? = self.defaultSampler(self.device)
    
    func defaultSampler(_ device: MTLDevice) -> MTLSamplerState {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.nearest
        sampler.magFilter             = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter             = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = FLT_MAX
        return device.makeSamplerState(descriptor: sampler)
    }
    
    convenience init(name: String, vertices: Array<Vertex>, device: MTLDevice, texture: MTLTexture? = nil) {
        var vertexData = Array<Float>()
        for vertex in vertices{
            vertexData += vertex.floatBuffer()
        }
        let dataSize = vertexData.count * MemoryLayout<Float>.size

        self.init(name: name, vertices: vertexData, verticesSize: dataSize, vertexCount: vertices.count, device: device, texture: texture)
    }
    
    init(name: String, vertices: UnsafeRawPointer, verticesSize: Int, vertexCount: Int, device: MTLDevice, options: MTLResourceOptions = [], texture: MTLTexture? = nil) {
        self.name = name
        self.device = device
        self.vertexCount = vertexCount
        self.texture = texture
        self.vertexBuffer = device.makeBuffer(bytes: vertices, length: verticesSize, options: options)
    }
    
    func createBufferProvider() -> BufferProvider {
        let sizeOfUniformsBuffer = MemoryLayout<Float>.size * (2 * float4x4.numberOfElements()) + Light.size()
        return BufferProvider(device: device, inflightBuffersCount: 3, bufferSize: sizeOfUniformsBuffer)
    }
    
    func buildUniformData(drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4) -> MTLBuffer {
        fatalError("Function not implemented in subclass \(#function)")
    }
    
    func render(_ commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor?) {
        
        let _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer.addCompletedHandler { (commandBuffer) -> Void in
            self.bufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setCullMode(MTLCullMode.front)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        if let texture = self.texture {
            renderEncoder.setFragmentTexture(texture, at: 0)
        }
        if let samplerState = samplerState {
            renderEncoder.setFragmentSamplerState(samplerState, at: 0)
        }
        
        let uniformBuffer = self.buildUniformData(drawable: drawable, parentModelViewMatrix: parentModelViewMatrix, projectionMatrix: projectionMatrix)
        
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: self.vertexCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
    func modelMatrix() -> float4x4 {
        var matrix = float4x4()
        matrix.translate(position.x, y: position.y, z: position.z)
        matrix.rotateAroundX(rotation.x, y: rotation.y, z: rotation.z)
        matrix.scale(scale, y: scale, z: scale)
        return matrix
    }

}
