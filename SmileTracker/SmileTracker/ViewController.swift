//
//  ViewController.swift
//  SmileTracker
//
//  Created by mac on 05/02/19.
//  Copyright © 2019 MMF. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController {
    let sceneView = ARSCNView()
    let smileLabel = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        //check weather device supports facetracking or not.
        guard ARFaceTrackingConfiguration.isSupported else{
            fatalError("Device does not support face Tracking.")
        }
        //asking for video capture permission.
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
            if granted{
                DispatchQueue.main.async {
                    //setup ui code goes here.
                    self.setupSmileTracker()
                }
            }else{
                Alert.toast(title: "Smile Tracker", message: "Camera access denied.", time: 2, presenterVC: self, completion: nil)
            }
        }
    }
    func setupSmileTracker(){
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
        sceneView.delegate = self
        sceneView.frame = CGRect(x: 20, y: self.view.frame.maxY - ((self.view.frame.height * 0.25) + 20), width: self.view.frame.width / 2 - 40, height: self.view.frame.height * 0.25 )
        sceneView.backgroundColor = .black
        sceneView.layer.cornerRadius = 10
        sceneView.layer.masksToBounds = true
        sceneView.layer.borderWidth = 2
        sceneView.layer.borderColor = UIColor.purple.cgColor
        view.addSubview(sceneView)
        
        smileLabel.text = "😐"
        smileLabel.font = UIFont.systemFont(ofSize: 150)
        view.addSubview(smileLabel)
        // Set constraints
        smileLabel.translatesAutoresizingMaskIntoConstraints = false
        smileLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        smileLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func handleSmile(leftValue: CGFloat, rightValue: CGFloat) {
        let smileValue = (leftValue + rightValue)/2.0
        switch smileValue {
        case _ where smileValue > 0.5:
            smileLabel.text = "😁"
        case _ where smileValue > 0.2:
            smileLabel.text = "🙂"
        default:
            smileLabel.text = "😐"
        }
    }
}
extension ViewController: ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // getting face anchor from renderer func.
        guard let faceAnchor = anchor as? ARFaceAnchor else{return}
        
        //get smile values from face anchore.
        let leftSmileValue = faceAnchor.blendShapes[.mouthSmileLeft] as! CGFloat
        let rightSmileValue = faceAnchor.blendShapes[.mouthSmileRight] as! CGFloat
        
        DispatchQueue.main.async {
            //refresh label.
            self.handleSmile(leftValue: leftSmileValue, rightValue: rightSmileValue)
        }
    }
}
