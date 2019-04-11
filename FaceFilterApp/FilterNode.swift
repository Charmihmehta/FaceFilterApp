//
//  FilterNode.swift
//  FaceFilterApp
//
//  Created by Charmi Mehta on 2019-04-09.
//  Copyright © 2019 Abita Shiney. All rights reserved.hhh
//

import SceneKit

class FilterNode: SCNNode {
    
    var options: [String]
    var index = 0
    
    init(with options: [String], width: CGFloat = 0.06, height: CGFloat = 0.06) {
        self.options = options
        
        super.init()
//
//        guard let image = UIImage(named: "nose1") else { return }
//        let pixelWidth = image.size.width * image.scale
//        let pixelHeight = image.size.height * image.scale
//        print(pixelWidth, pixelHeight)
//
//        let iphone7PlusPixelsPerInch: CGFloat = 326
//
//        //2. To Get The Image Size In Inches We Need To Divide By The PPI
//        let inchWidth = pixelWidth/iphone7PlusPixelsPerInch
//        let inchHeight = pixelHeight/iphone7PlusPixelsPerInch
//
//        //3. Calculate The Size In Metres (There Are 2.54 Cm's In An Inch)
//        let widthInMetres = (inchWidth * 2.54) / 100
//        let heightInMeters = (inchHeight * 2.54) / 100
//
//        let noseSize = SCNPlane(width: widthInMetres, height: heightInMeters)
//        noseSize.firstMaterial?.diffuse.contents = image
//        noseSize.firstMaterial?.isDoubleSided = true
       
      //  geometry = noseSize
        
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIImage(named: options.first!)
        plane.firstMaterial?.isDoubleSided = true
        
        geometry = plane
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}

// MARK: - Custom functions

extension FilterNode {
    
    func updatePosition(for vectors: [vector_float3]) {
        let newPos = vectors.reduce(vector_float3(), +) / Float(vectors.count)
        position = SCNVector3(newPos)
    }
    
    func next() {
        
        index = (index + 1) % options.count
        
        if let plane = geometry as? SCNPlane {
            plane.firstMaterial?.diffuse.contents = UIImage(named: options[index])
            plane.firstMaterial?.isDoubleSided = true
        }
    }
}

