//
//  CustomNode.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/5/23.
//

import ARKit

class CustomNode: SCNNode {
    
    
    let length: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(length: CGFloat = 2.13, width: CGFloat = 14.63, height: CGFloat = 4.27) {
        self.length = length
        self.width = width
        self.height = height

        super.init()
        
        DispatchQueue.main.async {
            self.createNodes()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createNodes() {
        let ringRadius = 0.25
        let pipeRadius = 0.1
        let torusGeometry = SCNTorus(ringRadius: ringRadius, pipeRadius: pipeRadius)
        torusGeometry.materials.first?.diffuse.contents = UIColor.blue
        let torusNode = SCNNode(geometry: torusGeometry)
        torusNode.position = SCNVector3(0, 0.98, 0)
        torusNode.rotation.x = Float.pi / 2
        
        let lineWidth = 0.1
        let lineHeight = 17.0
        let lineDepth = 0.1
        let lineBevelRadius = 0.5
        let lineGeometry = SCNBox(width: lineWidth, height: lineHeight, length: lineDepth, chamferRadius: lineBevelRadius)
        lineGeometry.materials.first?.diffuse.contents = UIColor.white
        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = SCNVector3(0, 9.5, 0)
        
        let textThickness = 0.40
        let textFontSize = 5.0
        let textFont = UIFont(name: "Helvetica", size: textFontSize)
        let textString = "Administrative Building"
        let textGeometry = SCNText(string: textString, extrusionDepth: textThickness)
        textGeometry.font = textFont
        textGeometry.isWrapped = false
        textGeometry.materials.first?.diffuse.contents = UIColor.tintColor
        let textMidwayPointX = (textGeometry.boundingBox.max.x - textGeometry.boundingBox.min.x) / 2.0
        let textMidwayPointY = (textGeometry.boundingBox.max.y - textGeometry.boundingBox.min.y) / 2.0
        let textDepth = textGeometry.boundingBox.max.z
        let textNode = SCNNode(geometry: textGeometry)
        
        let textPadding = CGFloat(1.0)
        let planeWidth = CGFloat(textGeometry.boundingBox.max.x - textGeometry.boundingBox.min.x) + (textPadding * 2)
        let planeHeight = CGFloat(textGeometry.boundingBox.max.y - textGeometry.boundingBox.min.y) + (textPadding * 2)
        let planeGeometry = SCNPlane(width: planeWidth, height: planeHeight)
        planeGeometry.materials.first?.diffuse.contents = UIColor.white
        let planeNode = SCNNode(geometry: planeGeometry)
        
        textNode.position = SCNVector3(-textMidwayPointX, -textMidwayPointY - Float(textPadding) + textDepth, textDepth)

        planeNode.position = SCNVector3(0, 20, 0)
        planeNode.addChildNode(textNode)
        
        
        // Create a parent node to hold the circle, line, and rectangle
        let containerNode = SCNNode()
        
        // Add the circle, line, and rectangle nodes as children of the parent node
        containerNode.addChildNode(torusNode)
        containerNode.addChildNode(lineNode)
        containerNode.addChildNode(planeNode)
        containerNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        
        // Add the parent node to as a child to the CustomNode.
        let constraint = SCNBillboardConstraint()
        constraint.isIncremental = true
        constraint.influenceFactor = 0.5
        constraint.freeAxes = [.X, .Y]
        containerNode.constraints = [constraint]
        
        addChildNode(containerNode)
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
        let scale = 1.0 + (simd_clamp(distance, 5.0, 20.0) - 5.0) / 15.0
        let scaledVector = simd_make_float4(scale, scale, scale, 1.0)

        // Calculate distance between camera and node
        //let distance = simd_length(self.simdTransform.columns.3 - pointOfView.simdTransform.columns.3)

        // Define a scaling factor based on distance
        //let scale = min(max(1.0 / (distance + 1.0), 1.0), 2.5)

        // Apply scaling to the entire transform
        let scaledTransform = heightAdjustedTransform * simd_float4x4(diagonal: scaledVector)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        self.simdTransform = scaledTransform
        SCNTransaction.commit()
        
    }

}
