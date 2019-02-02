//
//  ViewController.swift
//  GeometryFighterARKit
//
//  Created by mac on 02/02/19.
//  Copyright © 2019 MMF. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController,ARSessionDelegate {

    @IBOutlet weak var arSceneView: ARSCNView!
    @IBOutlet weak var sessionInfoView: UIVisualEffectView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    
    var geometryNode:SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        // Start the view's AR session with a configuration that uses the rear camera,
        // device position and orientation tracking, and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arSceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        arSceneView.session.delegate = self
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        arSceneView.showsStatistics = true
    }
    func setView(){
        // showStatistics enables a real-time statistics panel at the bottom of your scene
        arSceneView.showsStatistics = true
        
        // allowsCameraControl lets you manually control the active camera through simple gestures.
        arSceneView.allowsCameraControl = true
        
        // autoenablesDefaultLighting creates a generic omnidirectional light in your scene
        arSceneView.autoenablesDefaultLighting = true
    }
    

    func addGeometry(x: Float = 0, y: Float = 0, z: Float = -0.2) {
        // create a placeholder geometry variable
        var geometry:SCNGeometry
        
        // handle the returned shape from ShapeType.random()
        switch ShapeType.random() {
        case .Box:
            geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        case .Capsule:
            geometry = SCNCapsule(capRadius: 0.1, height: 0.2)
        case .Cone:
            geometry = SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.2)
        case .Cylinder:
            geometry = SCNCylinder(radius: 0.1, height: 0.2)
        case .Pyramid:
            geometry = SCNPyramid(width: 0.1, height: 0.2, length: 0.1)
        case .Sphere:
            geometry = SCNSphere(radius: 0.1)
        case .Torus:
            geometry = SCNTorus(ringRadius: 0.05, pipeRadius: 0.1)
        case .Tube:
            geometry = SCNTube(innerRadius: 0.025, outerRadius: 0.05, height: 0.2)
        }
        
        //  creates an instance of SCNNode named geometryNode.
        geometryNode = SCNNode(geometry: geometry)
        let light = SCNLight()
        light.type = .directional
        light.intensity = 0
        light.temperature = 0
        geometryNode?.light = light
        geometryNode!.position = SCNVector3(x, y, z)
        geometryNode!.geometry?.firstMaterial?.diffuse.contents = UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)


        arSceneView.scene.rootNode.addChildNode(geometryNode!)
    }
    @IBAction func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: arSceneView)
        let hitTestResults = arSceneView.hitTest(tapLocation)
        guard let node = hitTestResults.first?.node else {
            let hitTestResultsWithFeaturePoints = arSceneView.hitTest(tapLocation, types: .featurePoint)
            if let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
                let translation = hitTestResultWithFeaturePoints.worldTransform.translation
                addGeometry(x: translation.x, y: translation.y, z: translation.z)
            }
            return
        }
        node.removeFromParentNode()
    }
    func updateLightNodesLightEstimation() {
        DispatchQueue.main.async {
            guard let lightEstimate = self.arSceneView.session.currentFrame?.lightEstimate
                else { return }
            
            let ambientIntensity = lightEstimate.ambientIntensity
            let ambientColorTemperature = lightEstimate.ambientColorTemperature
            
            for lightNode in self.arSceneView.nodesInsideFrustum(of: self.arSceneView.scene.rootNode) {
                guard let light = lightNode.light else { continue }
                light.intensity = ambientIntensity
                light.temperature = ambientColorTemperature
            }
        }
    }
    // MARK: - Private methods
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal and vertical surfaces."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
     //MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]

        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")

        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
