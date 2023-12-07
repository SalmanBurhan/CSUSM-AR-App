//
//  LocationNode.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/6/23.
//

import Foundation
import ARKit

class LocationNode: SCNNode {
    let location: Concept3DLocation
    let category: Concept3DCategory
    var view: LocationNodeUIView?
    var viewNode: SCNNode?
    let width: CGFloat
    let height: CGFloat
    var lastReportedDistance: Float
    
    init(_ location: Concept3DLocation, _ category: Concept3DCategory, width: CGFloat) {
        self.height = round(width * 0.2877697842)
        self.width = width
        self.location = location
        self.category = category
        self.lastReportedDistance = 0
        super.init()
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let view = LocationNodeUIView()
        view.configure(name: location.name, category: category.name, categoryImageURL: category.iconURL, distance: 0.0)
        
        let whiteMaterial = SCNMaterialBuilder().withColor(.white.withAlphaComponent(0.70)).build()
        let viewMaterial = SCNMaterialBuilder().withView(view).build()
        
        let boxGeometry = SCNBox(width: self.width, height: self.height, length: 0.61, chamferRadius: 0.5)
        boxGeometry.materials = [
            viewMaterial, /// Front
            whiteMaterial, /// Right
            whiteMaterial, /// Rear
            whiteMaterial, /// Left
            whiteMaterial, /// Top
            whiteMaterial  /// Bottom
        ]
        
        self.view = view
        self.viewNode = SCNNode(geometry: boxGeometry)
        
        let constraint = SCNBillboardConstraint()
        constraint.isIncremental = true
        constraint.influenceFactor = 0.5
        constraint.freeAxes = [.X, .Y]
        self.viewNode?.constraints = [constraint]
        
        if let viewNode = self.viewNode {
            self.addChildNode(viewNode)
        }
    }
    
    public func updateTransform(_ transform: matrix_float4x4) {
        self.simdTransform = transform
        print("update transform")
    }

    public func updateTransform(_ transform: matrix_float4x4, withScalingFromPOV pointOfView: SCNNode?) {
        guard let povNode = pointOfView else {
            self.updateTransform(transform)
            return
        }
        
        var heightAdjustedTransform = transform
        //heightAdjustedTransform.columns.3.y += Float(self.height)
        self.simdTransform = heightAdjustedTransform

        let distance = simd_distance(povNode.simdPosition, self.simdPosition)
        
        /// Only Update The Distance Label of The Node If The Difference Between The Last Update Is >= 10 Feet.
        if abs(lastReportedDistance - distance) >= 3.048 {
            DispatchQueue.main.async {
                self.view?.configure(distance: distance)
            }
            self.lastReportedDistance = distance
        }
        
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

}
