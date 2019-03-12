//
//  ViewController.swift
//  myFirstScene
//
//  Created by mac on 07/02/19.
//  Copyright © 2019 MMF. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var myObjects : SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        addLight()
        
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

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    // MARK: - Gesture Recognizers
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location)
        guard let node = hitTestResults.first?.node else {
            guard let feturePointResult = sceneView.hitTest(location, types: .existingPlane).first else { return }
            
            let position = SCNVector3Make(feturePointResult.worldTransform.columns.3.x,
                                          feturePointResult.worldTransform.columns.3.y,
                                          feturePointResult.worldTransform.columns.3.z)
            addModelTo(position: position)
            return
        }
        node.removeFromParentNode()
    }
    func addModelTo(position: SCNVector3) {
        // get 3d model and create scene of it
        guard let myScene = SCNScene(named: "art.scnassets/myScene.scn") else {
            fatalError("Unable to find myScene.scn")
        }
        // get the refrence of containerNode
        guard let containerNode = myScene.rootNode.childNode(withName: "ContainerNode", recursively: true) else {
            fatalError("Unable to find ContainerNode")
        }
        // set the position of containerNode to the position detected by hit testing.
        containerNode.position = position
        containerNode.scale = SCNVector3Make(0.005, 0.005, 0.005)
        
        // get the refrence of personNode node
        guard let personNode = containerNode.childNode(withName: "personNode", recursively: true)else{return}
        let circularNode = personNode.childNode(withName: "geosphere", recursively: true)
        let cylindricalNode = personNode.childNode(withName: "cylinder", recursively: true)
        let tabletNode = personNode.childNode(withName: "capsule", recursively: true)
        let physicalMaterial = SCNMaterial()
        physicalMaterial.lightingModel = .physicallyBased
        physicalMaterial.diffuse.contents = UIColor.orange
        physicalMaterial.metalness.contents = 0.85
        physicalMaterial.roughness.contents = 0.15
        circularNode?.geometry?.firstMaterial = physicalMaterial
        cylindricalNode?.geometry?.firstMaterial = physicalMaterial
        tabletNode?.geometry?.firstMaterial = physicalMaterial
        let planeMaterial = SCNMaterial()
        planeMaterial.lightingModel = .physicallyBased
        planeMaterial.diffuse.contents = UIColor.orange
        planeMaterial.metalness.contents = 0.85
        planeMaterial.roughness.contents = 0.30
        let planeNode = containerNode.childNode(withName: "plane", recursively: true)
        planeNode?.geometry?.firstMaterial = planeMaterial
        myObjects = containerNode
        sceneView.scene.rootNode.addChildNode(myObjects!)
    }
    func addLight() {
        // Create a light and set the type to .directional (Only directional and spot lights can cast shadows).
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        // We only want the light to cast shadows and we don’t want to have any effect on the lighting. This can be achieved by setting the intensity to zero.
        directionalLight.intensity = 0
        // We set castsShadow to true and shadowMode to .deferred so that shadows are not applied when rendering the objects. Instead, it would be applied as a final post-process (This is required for casting shadows on the invisible plane).
        directionalLight.castsShadow = true
        directionalLight.shadowMode = .deferred
        // We create a black color with 50% opacity and set it as our shadowColor. This will make our shadows look more grey and realistic as opposed to the default dark black color.
        directionalLight.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        // We increase its shadowSampleCount to create smoother and higher resolution shadows.
        directionalLight.shadowSampleCount = 10
        // Finally, we create a node, attach our light to it, and rotate it so that it’s facing the floor at a slightly downward angle. Then, add it to the root node of the scene.
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.rotation = SCNVector4Make(1, 0, 0, -Float.pi / 3)
        sceneView.scene.rootNode.addChildNode(directionalLightNode)
    }
    @objc
    func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = myObjects else { return }
        var originalScale = myObjects?.scale
        
        switch gesture.state {
        case .began:
            originalScale = myObjects?.scale
            gesture.scale = CGFloat((myObjects?.scale.x)!)
        case .changed:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.005{ newScale = SCNVector3(x: 0.005, y: 0.005, z: 0.005) }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            myObjects?.scale = newScale
        case .ended:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.005{ newScale = SCNVector3(x: 0.005, y: 0.005, z: 0.005) }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            myObjects?.scale = newScale
            gesture.scale = CGFloat((myObjects?.scale.x)!)
        default:
            gesture.scale = 1.0
            originalScale = nil
        }
    }
}
