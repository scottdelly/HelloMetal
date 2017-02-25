//
//  MetalViewController.swift
//  HelloMetal
//
//  Created by Scott Delly on 2/16/17.
//  Copyright © 2017 ScottDelly. All rights reserved.
//


import UIKit
import MetalKit
import QuartzCore
import simd

class MetalViewController: UIViewController {
    
    typealias NodeType = TextNode
    
    var textureLoader: MTKTextureLoader! = nil
    var renderer: Renderer<NodeType>!
    var objectToDraw: Node!
    
    let panSensivity:Float = 5.0
    var lastPanLocation: CGPoint!
    
    @IBOutlet weak var mtkView: MTKView! {
        didSet {
            self.mtkView.delegate = self
            self.mtkView.preferredFramesPerSecond = 60
            self.mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let device = MTLCreateSystemDefaultDevice()!
        self.renderer = TextRenderer(device: device, aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height))
        self.mtkView.device = device
        self.textureLoader = MTKTextureLoader(device: device)
        
        let sampleText = "It was the best of times, it was the worst of times, " +
        "it was the age of wisdom, it was the age of foolishness...\n\n" +
        "Все счастливые семьи похожи друг на друга, " +
        "каждая несчастливая семья несчастлива по-своему."
        let textRect = UIScreen.main.nativeBounds.insetBy(dx: 10, dy: 10)
        
        let node = TextNode(string: sampleText, inRect: textRect, withFont: UIFont.systemFont(ofSize: 72), device: device)
        node.scale = 1
        self.objectToDraw = node
           
        self.setupGestures()
    }
    
    func updateLogic(_ timeSinceLastUpdate: CFTimeInterval) {
        (self.objectToDraw as? AnimatedNode)?.updateWithDelta(timeSinceLastUpdate)
    }
    
    //MARK: - Gesture related
    // 1
    func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MetalViewController.pan(_:)))
        self.view.addGestureRecognizer(pan)
    }
    
    // 2
    func pan(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == UIGestureRecognizerState.changed {
            let pointInView = panGesture.location(in: self.view)
            // 3
            let xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
            let yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
            // 4
            objectToDraw.rotation.y -= xDelta
            objectToDraw.rotation.x -= yDelta
            lastPanLocation = pointInView
        } else if panGesture.state == UIGestureRecognizerState.began {
            lastPanLocation = panGesture.location(in: self.view)
        }
    }
}

// MARK: - MTKViewDelegate
extension MetalViewController: MTKViewDelegate {
    
    // 1
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.renderer.projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0),
                                                                           aspectRatio: Float(size.width / size.height),
                                                                           nearZ: 0.01, farZ: 100.0)
    }
    
    // 2
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        self.renderer.render(node: self.objectToDraw, inDrawable: drawable)
    }
}
