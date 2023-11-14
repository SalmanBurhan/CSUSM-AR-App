//
//  ARRenderer.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/12/23.
//

import Foundation
import SceneKit
import ARKit
import ARCore

class ARRenderer {
    
    let sceneView: ARSCNView
    var renderedStreetscapes: [UUID: SCNNode] = [:]
    var renderedRooftopAnchors: [UUID: SCNNode] = [:]
    
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    func renderStreetscapeMesh(geometries: GARStreetscapeGeometry, color: UIColor) {
        if renderedStreetscapes[geometries.identifier] == nil {
            var vertices: [SCNVector3] = []
            var triangles: [UInt32] = []
            for point in UnsafeBufferPointer(start: geometries.mesh.vertices, count: Int(geometries.mesh.vertexCount)) {
                vertices.append(SCNVector3(point.x, point.y, point.z))
            }
            let geometrySource = SCNGeometrySource(vertices: vertices)
            for triangle in UnsafeBufferPointer(start: geometries.mesh.triangles, count: Int(geometries.mesh.triangleCount)) {
                triangles.append(triangle.indices.0)
                triangles.append(triangle.indices.1)
                triangles.append(triangle.indices.2)
            }
            let geometryElement = SCNGeometryElement(indices: triangles, primitiveType: .triangles)
            let geometryFinal = SCNGeometry(sources: [geometrySource], elements: [geometryElement])
            let node = SCNNode(geometry: geometryFinal)
            node.geometry?.firstMaterial?.diffuse.contents = color
            node.geometry?.firstMaterial?.fillMode = .lines
            self.sceneView.scene.rootNode.addChildNode(node)
            //print("Rendering StreetscapeGeometry(identifier: \(geometries.identifier))")
            renderedStreetscapes[geometries.identifier] = node
        }
        renderedStreetscapes[geometries.identifier]!.simdTransform = geometries.meshTransform
    }
    
    func renderCircle(at location: simd_float4x4, id: UUID) {
        if renderedRooftopAnchors[id] == nil {

            let radius: CGFloat = 0.5
            let circle = SCNSphere(radius: radius)
            circle.firstMaterial?.diffuse.contents = UIColor.red
            
            let node = SCNNode(geometry: circle)
            node.simdTransform = location
            
            self.sceneView.scene.rootNode.addChildNode(node)
            
            renderedRooftopAnchors[id] = node
        }
    }
    
    func createRooftopCard(for location: simd_float4x4, text: String) -> SCNNode {
        // Warning: Programmatically generating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        let textDepth: Float = 0.1
    
        // Billboard contraint to force text to always face the user
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // SCN Text
        let scnText = SCNText(string: text, extrusionDepth: CGFloat(textDepth))
        let font = UIFont(name: "Helvetica", size: 0.15)
        scnText.font = font
        scnText.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        scnText.firstMaterial?.diffuse.contents = UIColor.universityBlue
        scnText.firstMaterial?.specular.contents = UIColor.white
        scnText.firstMaterial?.isDoubleSided = true
        scnText.chamferRadius = CGFloat(textDepth)
        
        // Text Node
        let (minBound, maxBound) = scnText.boundingBox
        let textNode = SCNNode(geometry: scnText)
        // Centre Node - to Centre-Bottom point
        textNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x) / 2.0, minBound.y, textDepth / 2.0)
        // Reduce default text size
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // Sphere Node
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // Text Parent Node
        let textParentNode = SCNNode()
        textParentNode.addChildNode(textNode)
        textParentNode.addChildNode(sphereNode)
        textParentNode.constraints = [billboardConstraint]
        
        textParentNode.simdTransform = location
        
        return textParentNode
    }
        
    func removeRenderedContent() {
        for streetscape in renderedStreetscapes.values {
            streetscape.removeFromParentNode()
        }
        renderedStreetscapes = [:]
        
        for rooftopAnchor in renderedRooftopAnchors.values {
            rooftopAnchor.removeFromParentNode()
        }
        renderedRooftopAnchors = [:]
    }

}
