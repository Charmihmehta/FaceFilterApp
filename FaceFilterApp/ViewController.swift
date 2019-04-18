//
//  ViewController.swift
//  FaceFilterApp
//cxc
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

    fileprivate let screenView:UIView = UIView(frame: CGRect(origin: CGPoint.zero, size: SNUtils.screenSize))
    fileprivate let slider:SNSlider = SNSlider(frame: CGRect(origin: CGPoint.zero, size: SNUtils.screenSize))
    fileprivate let textField = SNTextField(y: SNUtils.screenSize.height/2, width: SNUtils.screenSize.width, heightOfScreen: SNUtils.screenSize.height)
    fileprivate let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer()
     fileprivate var data:[SNFilter] = []
    
    @IBAction func saveScreenhot(){
        
        //1. Create A Snapshot
        let snapShot:UIImage = self.sceneView.snapshot()
        
        //2. Save It The Photos Album
        UIImageWriteToSavedPhotosAlbum(snapShot, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
  
    
    @IBAction func shareImageTapped(_ sender: Any) {
        let snapShot:UIImage = self.sceneView.snapshot()
       guard let image = UIImage(named: "eye4") else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        print("btn clicked")
        activityController.completionWithItemsHandler = { (nil, completed, _, error) in
            if completed {
                print("completed")
            } else {
                print("cancled")
            }
        }
        present(activityController, animated: true) {
            print("presented")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        tapGesture.addTarget(self, action: #selector(handleTf))
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        setupTextField()
        setupSlider()
        view.addSubview(screenView)
    
    }

//func filterButtonTapped(sender: UIButton) {
//    let button = sender as UIButton
//    
//    sceneView = button.backgroundImageForState(UIControl.State.Normal) as! UIImage
//}
    
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
    
    fileprivate func setupTextField() {
        self.screenView.addSubview(textField)
        
        self.tapGesture.delegate = self
        self.slider.addGestureRecognizer(tapGesture)
       
        
//        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillShow(_:)), name: NSNotification.Name.UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillHide(_:)), name: NSNotification.Name.UIResponder.keyboardWillHideNotification, object: nil)
//        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardTypeChanged(_:)), name: NSNotification.Name.UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    fileprivate func setupSlider() {
        self.createData(UIImage(named: "eye1")!)
        self.slider.dataSource = self
        self.slider.isUserInteractionEnabled = true
        self.slider.isMultipleTouchEnabled = true
        self.slider.isExclusiveTouch = false

        self.screenView.addSubview(slider)
        self.slider.reloadData()
    }
    
    fileprivate func createData(_ image: UIImage) {
        self.data = SNFilter.generateFilters(SNFilter(frame: self.slider.frame, withImage: image), filters: SNFilter.filterNameList)
        self.data[1].addSticker(SNSticker(frame: CGRect(x: 195, y: 30, width: 90, height: 90), image: UIImage(named: "stick2")!))
        self.data[2].addSticker(SNSticker(frame: CGRect(x: 30, y: 100, width: 250, height: 250), image: UIImage(named: "stick3")!))
        self.data[3].addSticker(SNSticker(frame: CGRect(x: 20, y: 00, width: 140, height: 140), image: UIImage(named: "stick")!))
    }
    
    fileprivate func updatePicture(_ newImage: UIImage) {
        createData(newImage)
        slider.reloadData()
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

extension ViewController: SNSliderDataSource {

    func numberOfSlides(_ slider: SNSlider) -> Int {
        return data.count
    }

    func slider(_ slider: SNSlider, slideAtIndex index: Int) -> SNFilter {

        return data[index]
    }

    func startAtIndex(_ slider: SNSlider) -> Int {
        return 0
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
