//
//  CustomNode.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/5/23.
//

import ARKit

class CustomNode: SCNNode {
    
    override init() {
        super.init()
        createNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func createNodes() {
        // Create a circular base node (circle)
        let circleGeometry = SCNCylinder(radius: 0.1, height: 0.01)
        let circleNode = SCNNode(geometry: circleGeometry)
        circleNode.position = SCNVector3(0, 0, 0)  // Adjust the position as needed
        circleNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        addChildNode(circleNode)
        
        // Create a line node stemming from the circle
        let lineGeometry = SCNCylinder(radius: 0.01, height: 1.0)  // Adjust the height as needed
        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = SCNVector3(0, 0.5, -2.0)  // Adjust the position and height as needed
        lineNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)  // Rotate the line to point upward
        lineNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        addChildNode(lineNode)
        
        // Create a rectangular shape 10 ft above the circle
        let boxGeometry = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.position = SCNVector3(0, 1.0, -2.0)  // Adjust the position and height as needed
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        addChildNode(boxNode)
    }
}
