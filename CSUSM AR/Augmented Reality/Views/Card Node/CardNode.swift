//
//  CardNode.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/28/23.
//

import SceneKit

class CardNode: SCNNode {
    
    let length: CGFloat
    let width: CGFloat
    let height: CGFloat
    let text: String
    
    /// Creates a CardNode with specified height, width, and depth in meters.
    init(length: CGFloat = 2.13, width: CGFloat = 14.63, height: CGFloat = 4.27, text: String) {

        self.length = length
        self.width = width
        self.height = height
        self.text = text
        
        super.init()
        
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Create a box geometry with the specified width, height, and depth
        let boxGeometry = SCNBox(width: self.width, height: self.height, length: self.length, chamferRadius: 0.5)
        let boxNode = SCNNode(geometry: boxGeometry)
        
        // Set up the appearance of the box (you can customize this)
        let whiteMaterial = SCNMaterialBuilder().withColor(.white).build()
        let cardView = CardNodeUIView(text: self.text)
        let cardMaterial = SCNMaterialBuilder().withView(cardView).build()
        boxGeometry.materials = [
            cardMaterial, /// Front
            whiteMaterial, /// Right
            cardMaterial, /// Rear
            whiteMaterial, /// Left
            whiteMaterial, /// Top
            whiteMaterial  /// Bottom
        ]
        
        // Add the box node to the card node
        self.addChildNode(boxNode)
        
        // Always Face Camera Position
        self.constraints = [SCNBillboardConstraint()]
    }
    
    func updateTransform(_ transform: matrix_float4x4, withScalingFromPOV pointOfView: SCNNode?) {
        guard let povNode = pointOfView else {
            self.updateTransform(transform)
            return
        }
        
        var heightAdjustedTransform = transform
        heightAdjustedTransform.columns.3.y += Float(self.height)
        self.simdTransform = heightAdjustedTransform

        let distance = simd_distance(povNode.simdPosition, self.simdPosition)
        let scale = 1.0 + (simd_clamp(distance, 5.0, 20.0) - 5.0) / 15.0
        let scaledVector = simd_make_float4(scale, scale, scale, 1.0)

        // Calculate distance between camera and node
        //let distance = simd_length(self.simdTransform.columns.3 - pointOfView.simdTransform.columns.3)

        // Define a scaling factor based on distance
        //let scale = min(max(1.0 / (distance + 1.0), 1.0), 2.5)

        // Apply scaling to the entire transform
        let scaledTransform = heightAdjustedTransform * simd_float4x4(diagonal: scaledVector)

        self.simdTransform = scaledTransform
    }
    
    func updateTransform(_ transform: matrix_float4x4) {
        //print("Updating Transform of CardNode for \(self.text)")
        var heightAdjustedTransform = transform
        heightAdjustedTransform.columns.3.y += Float(self.height)
        self.simdTransform = heightAdjustedTransform
    }
    
}
