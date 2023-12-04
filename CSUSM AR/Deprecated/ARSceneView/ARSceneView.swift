//
//  ARSceneView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/1/23.
//

import Foundation
import SwiftUI
import ARKit

/// Wrapping an `ARSCNView` from `UIKit` into a context usable in a `SwiftUI` view.
//struct ARSceneView: UIViewRepresentable {
//    
//    let sceneView = ARSCNView()
//    var session: ARSession { self.sceneView.session }
//    var scene: SCNScene { self.sceneView.scene }
//
//    init() {
//    }
//    
//    func makeUIView(context: Context) -> some ARSCNView {
//        sceneView.automaticallyUpdatesLighting = true;
//        sceneView.autoenablesDefaultLighting = true;
//        sceneView.debugOptions = [.showFeaturePoints]
//        return sceneView
//    }
//    
//    func updateUIView(_ uiView: UIViewType, context: Context) { }
//    
//}
