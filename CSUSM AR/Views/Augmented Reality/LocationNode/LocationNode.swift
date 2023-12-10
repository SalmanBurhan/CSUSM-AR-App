//
//  LocationNode.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/6/23.
//

import Foundation
import ARKit

/// A custom SCNNode subclass that represents a location in augmented reality.
class LocationNode: SCNNode {

    // MARK: - Properties

    /// The location represented by the node.
    let location: Concept3DLocation
    
    /// The category of the location represented by the node.
    let category: Concept3DCategory
    
    /// The view for the location node.
    var view: LocationNodeUIView?
    
    /// The node for the location view.
    var viewNode: SCNNode?
    
    /// The width of the node in meters.
    let width: CGFloat
    
    /// The height of the node in meters.
    /// This is calculated as ~ 30% of the width.
    let height: CGFloat
    
    /// The last reported distance of the node from the camera position.
    var lastReportedDistance: Float
    
    // MARK: - Initialization

    /**
     Initializes a LocationNode with the given location and category.
     - Parameters:
        - location: The location represented by the node.
        - category: The category of the location represented by the node.
        - width: The width of the node in meters.
    */
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
    
    /// Initializes a LocationNode with the given decoder.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup

    /// Performs common initialization tasks for the node.
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
    
    // MARK: - Update

    /**
     Updates the transform of the node.
     - Parameters:
        - transform: The transform to apply to the node.
    */
    public func updateTransform(_ transform: matrix_float4x4) {
        self.simdTransform = transform
        print("update transform")
    }

    /**
     Updates the transform of the node.
     - Parameters:
        - transform: The transform to apply to the node.
        - pointOfView: The point of view to use for scaling the node.
    */
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
