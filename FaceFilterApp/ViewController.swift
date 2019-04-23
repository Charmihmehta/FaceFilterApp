//
//  ViewController.swift
//  FaceFilterApp
//
//  Created by Abita Shiney on 2019-04-06.
//  Copyright © 2019 Abita Shiney. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation
import SnapSliderFilters

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    let noseOptions = ["nose4","nose3","nose2"]
    let eyeOptions = ["eye4","eye2","eye5","eye7"]
    let mouthOptions = ["mouth7","mustache","mouth4","mouth8"]
    let hatOptions = ["hat1", "hat2","head3","head8","head9","head10"]
    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[8], [1064], [42], [24, 25], [20]]
    
    fileprivate let textField = SNTextField(y: SNUtils.screenSize.height/2, width: SNUtils.screenSize.width, heightOfScreen: SNUtils.screenSize.height)
    fileprivate let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        setupTextField()
      //  view.addSubview(sceneView)
        tapGesture.addTarget(self, action: #selector(handleTf))
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
        NotificationCenter.default.removeObserver(textField)
    }
    
    @IBAction func saveScreenhot(){
     //   1. Create a Snapshot
       // let snapShot:UIImage = self.sceneView.snapshot()

        //2. Save It The Photos Album
      //  UIImageWriteToSavedPhotosAlbum(snapShot, self, nil, nil)

         let screenShot = snapshot(of: CGRect(x: 0, y: 0, width: 828, height: 1792))
        UIImageWriteToSavedPhotosAlbum(screenShot!, self, nil, nil)
        showToast(message: "Saved")
       
    }
  
    func snapshot(of rect: CGRect? = nil) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.sceneView.bounds.size, self.sceneView.isOpaque, 0)
        self.sceneView.drawHierarchy(in: self.sceneView.bounds, afterScreenUpdates: true)
        let fullImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = fullImage, let rect = rect else { return fullImage }
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
    
    @IBAction func shareImageTapped(_ sender: Any) {
       // let snapShot:UIImage = self.sceneView.snapshot()
        let shareScreenShot = snapshot(of: CGRect(x: 0, y: 0, width: 828, height: 1792))
        var imagesToShare = [AnyObject]()
        imagesToShare.append(shareScreenShot!)

        let activityViewController = UIActivityViewController(activityItems: imagesToShare , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        let locations = sender.location(in: sceneView)
        let results = sceneView.hitTest(locations, options: nil)
        if let result = results.first,
            let node = result.node as? FilterNode {
            node.next()
        }
        else{
            self.textField.handleTap()
        }
    }
    
    @IBAction func refreshBtnTapped(_ sender: UITapGestureRecognizer) {
        let location = (sender).location(in: sceneView)
        let results = sceneView.hitTest(location, options: nil)
        if let result = results.first,
            let node = result.node as? FilterNode {
            node.next()
        }
        
    }
    
    fileprivate func setupTextField() {
        self.sceneView.addSubview(textField)
        self.tapGesture.delegate = self
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-180, width: 125, height: 35))
        toastLabel.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        toastLabel.textColor = UIColor.black
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 5;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
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

extension ViewController: UIGestureRecognizerDelegate {

    @objc func handleTf() {
        self.textField.handleTap()
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
        noseNode.scale = SCNVector3(0.9, 0.6, 0.7)
        node.addChildNode(noseNode)
        
       
        let leftEyeNode = FilterNode(with: eyeOptions)
        leftEyeNode.name = "leftEye"
        leftEyeNode.scale = SCNVector3(1.1, 0, 1.1)
        leftEyeNode.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
        node.addChildNode(leftEyeNode)
        
        let rightEyeNode = FilterNode(with: eyeOptions)
        rightEyeNode.name = "rightEye"
        rightEyeNode.scale = SCNVector3(1.1, 0, 1.1)
        node.addChildNode(rightEyeNode)
        
        let mouthNode = FilterNode(with: mouthOptions)
        mouthNode.name = "mouth"
        mouthNode.scale = SCNVector3(0.7, 0.4, 0.6)
        node.addChildNode(mouthNode)
        
        let hatNode = FilterNode(with: hatOptions)
        hatNode.name = "hat"
        hatNode.scale = SCNVector3(2.7, 1.6, 2.5)
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
