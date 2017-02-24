////
////  ViewController.swift
////  HelloMetal
////
////  Created by Scott Delly on 2/16/17.
////  Copyright © 2017 ScottDelly. All rights reserved.
////
//
//import UIKit
//import Metal
//import QuartzCore
//import CoreMotion
//import simd
//
//class ViewController: UIViewController {
//
//    var lastFrameTimestamp: CFTimeInterval = 0.0
////    var motionManager = CMMotionManager()
//    var renderer: Renderer!
//    var timer: CADisplayLink!
//    var objectToDraw: Node!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.renderer = Renderer()
//
//        self.renderer.metalLayer.frame = self.view.layer.frame  // 5
//        self.view.layer.addSublayer(self.renderer.metalLayer)   // 6
//        
////        let cube = Cube(device: self.renderer.device)
//        let triangle = Triangle(device: self.renderer.device)
//        self.objectToDraw = triangle
//        
////        if self.motionManager.isDeviceMotionAvailable {
////            self.motionManager.deviceMotionUpdateInterval = 0.01
////            self.motionManager.startDeviceMotionUpdates()
////        }
//        
//        self.timer = CADisplayLink(target: self, selector: #selector(ViewController.newFrame(displayLink:)))
//        self.timer.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
//    }
//    
//    // 1
//    func newFrame(displayLink: CADisplayLink){
//        
//        if self.lastFrameTimestamp == 0.0 {
//            self.lastFrameTimestamp = displayLink.timestamp
//        }
//        
//        // 2
//        let elapsed = displayLink.timestamp - self.lastFrameTimestamp
//        self.lastFrameTimestamp = displayLink.timestamp
//        
//        // 3
//        self.gameloop(timeSinceLastUpdate: elapsed)
//    }
//    
//    func gameloop(timeSinceLastUpdate: CFTimeInterval) {
//        
//        // 4
//        (self.objectToDraw.update(delta: timeSinceLastUpdate)
//        
//        // 5
//        autoreleasepool {
//            self.render()
//        }
//    }
//    
//    func render() {
//        var worldModelMatrix = float4x4()
//        worldModelMatrix.translate(0.0, y: 0.0, z: -7.0)
////        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 25), y: 0.0, z: 0.0)
//        self.renderer.render(node: self.objectToDraw, inWorld: worldModelMatrix)
//    }
//
//}
//
