//
//  ViewController.swift
//  FaceFilterApp
//cxc
//  Created by Abita Shiney on 2019-04-06.
//  Copyright © 2019 Abita Shiney. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    let noseOptions = ["nose1","nose4","nose5"]
    let eyeOptions = ["eye1","eye2","eye4"]
    let mouthOptions = ["mouth1", "mustache","mouth4"]
    let hatOptions = ["hat2", "hat1", "head1", "hat3", "head2","head4","head5","head7","head9"]
    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[8], [1064], [42], [24, 25], [20]]

    @IBAction func saveScreenhot(){
        
        //1. Create A Snapshot
        let snapShot = self.sceneView.snapshot()
        
        //2. Save It The Photos Album
        UIImageWriteToSavedPhotosAlbum(snapShot, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
//     func touchesBegan(_ touches: UITapGestureRecognizer, with event: UIEvent?) {
//        let location = touches.location(in: sceneView)
//                let results = sceneView.hitTest(location, options: nil)
//                if let result = results.first,
//                    let node = result.node as? FilterNode {
//                    node.next()
//                }
//    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        let results = sceneView.hitTest(location, options: nil)
        if let result = results.first,
            let node = result.node as? FilterNode {
            node.next()
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        
        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            print("ARKit Scene Successfully Saved")
        }
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        for (feature, indices) in zip(features, featureIndices)  {
            let child = node.childNode(withName: feature, recursively: false) as? FilterNode
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            child?.updatePosition(for: vertices)
            
            switch feature {
            case "leftEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
              
            case "rightEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
            
            case "mouth":
                let jawOpenValue = anchor.blendShapes[.jawOpen]?.floatValue ?? 0.2
                child?.scale = SCNVector3(1.0, 0.8 + jawOpenValue, 1.0)
                
            default:
                break
            }
        }
    }
    
}
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let device = sceneView.device else {
                return nil
        }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceGeometry)
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 0.0
        let noseNode = FilterNode(with: noseOptions)
        noseNode.name = "nose"
        node.addChildNode(noseNode)
        
        
        
        let leftEyeNode = FilterNode(with: eyeOptions)
        leftEyeNode.name = "leftEye"
        leftEyeNode.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
        node.addChildNode(leftEyeNode)
        
        let rightEyeNode = FilterNode(with: eyeOptions)
        rightEyeNode.name = "rightEye"
        node.addChildNode(rightEyeNode)
        
        let mouthNode = FilterNode(with: mouthOptions)
        mouthNode.name = "mouth"
        node.addChildNode(mouthNode)
        
        let hatNode = FilterNode(with: hatOptions)
        hatNode.name = "hat"
        node.addChildNode(hatNode)
        updateFeatures(for: node, using: faceAnchor)
        
        return node
    }
    func renderer(
        _ renderer: SCNSceneRenderer,
        didUpdate node: SCNNode,
        for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        faceGeometry.update(from: faceAnchor.geometry)
        updateFeatures(for: node, using: faceAnchor)
        
        
    }
    
}
