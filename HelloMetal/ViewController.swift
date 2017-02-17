//
//  ViewController.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//

import UIKit
import Metal
import QuartzCore

class ViewController: UIViewController {

    weak var device: MTLDevice!
    weak var metalLayer: CAMetalLayer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    var objectToDraw: Node!
    var projectionMatrix: Matrix4!
    var lastFrameTimestamp: CFTimeInterval = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        
        let device = MTLCreateSystemDefaultDevice()
        
        let metalLayer = CAMetalLayer()          // 1
        metalLayer.device = device           // 2
        metalLayer.pixelFormat = .bgra8Unorm // 3
        metalLayer.framebufferOnly = true    // 4
        metalLayer.frame = self.view.layer.frame  // 5
        self.view.layer.addSublayer(metalLayer)   // 6
        
        self.device = device
        self.metalLayer = metalLayer
        
        let cube = Cube(device: self.device)

        self.objectToDraw = cube
        
        // 1
        let defaultLibrary = self.device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary!.makeFunction(name: "basic_vertex")
        
        // 2
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // 3
        do {
            self.pipelineState = try self.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }

        self.commandQueue = self.device.makeCommandQueue()
        
        self.timer = CADisplayLink(target: self, selector: #selector(ViewController.newFrame(displayLink:)))
        self.timer.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
    }
    
    func render() {
        if let drawable = self.metalLayer.nextDrawable() {
            let worldModelMatrix = Matrix4()!
            worldModelMatrix.translate(0.0, y: 0.0, z: -7.0)
            worldModelMatrix.rotateAroundX(Matrix4.degrees(toRad: 25), y: 0.0, z: 0.0)

            self.objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix ,clearColor: nil)
        }
    }
    
    // 1
    func newFrame(displayLink: CADisplayLink){
        
        if self.lastFrameTimestamp == 0.0 {
            self.lastFrameTimestamp = displayLink.timestamp
        }
        
        // 2
        let elapsed = displayLink.timestamp - self.lastFrameTimestamp
        self.lastFrameTimestamp = displayLink.timestamp
        
        // 3
        self.gameloop(timeSinceLastUpdate: elapsed)
    }
    
    func gameloop(timeSinceLastUpdate: CFTimeInterval) {
        
        // 4
        (self.objectToDraw as? AnimatedNode)?.update(delta: timeSinceLastUpdate)
        
        // 5
        autoreleasepool {
            self.render()
        }
    }}

