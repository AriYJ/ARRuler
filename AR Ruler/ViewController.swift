//
//  ViewController.swift
//  AR Ruler
//
//  Created by Ari Jane on 5/31/20.
//  Copyright © 2020 Ari Jane. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var dotNodes = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.showsStatistics = true
        
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.scene = scene
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchLocation = touches.first?.location(in: sceneView) {
            let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint) //we're not interested in detecting plane here. Just trying to track continuous surface
            if let hitResult = hitTestResults.first {
                addDot(at: hitResult)
            }
        }
    }
    
    func addDot(at hitResult: ARHitTestResult) {
        let dotGeometry = SCNSphere(radius: 0.005)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        dotGeometry.materials = [material]
        
        let sphereNode = SCNNode(geometry: dotGeometry)
        sphereNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(sphereNode)
        dotNodes.append(sphereNode)
        
        if dotNodes.count == 2 {
            calculate()
        } else if dotNodes.count == 5 { //2 touch nodes generate one line node and one text node
            for i in 0...3 {
                dotNodes[i].removeFromParentNode()
            }
            dotNodes = Array(dotNodes.dropFirst(4))
        }
    }

    func calculate() {
        let start = dotNodes[0]
        let end = dotNodes[1]
        
        makeLine(start, end)
        
        let distance = round(sqrt(
            pow(end.position.x - start.position.x, 2) +
            pow(end.position.y - start.position.y, 2) +
            pow(end.position.z - start.position.z, 2)
        ) * 100) / 100
        updateText(text: "\(abs(distance))", at: end.position)
    }
    
    func makeLine(_ start: SCNNode, _ end: SCNNode) {

        let sources = SCNGeometrySource(vertices: [start.position, end.position])
        let index: [Int32] = [0,1]
        let elements = SCNGeometryElement(indices: index, primitiveType: .line)
        let lineGeo = SCNGeometry(sources: [sources], elements: [elements])
        lineGeo.firstMaterial?.diffuse.contents = UIColor.red
        
        let lineNode = SCNNode(geometry: lineGeo)
        sceneView.scene.rootNode.addChildNode(lineNode)
        dotNodes.append(lineNode)
        
    }
    
    func updateText(text: String, at position: SCNVector3) {
        
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.red //fast way to add material
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = position //so that we don't need to set it at a positino relative to our phone, which makes it hard to find
        textNode.scale = SCNVector3(0.003, 0.003, 0.003) //scale text to be 1% of original size
        sceneView.scene.rootNode.addChildNode(textNode)
        dotNodes.append(textNode)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}
