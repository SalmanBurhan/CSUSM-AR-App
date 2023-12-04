//
//  MaterialBuilder.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/29/23.
//

import SceneKit
import SwiftUI
import UIKit

struct SCNMaterialBuilder {
    private var material: SCNMaterial
    
    init() {
        self.material = SCNMaterial()
        self.material.locksAmbientWithDiffuse = true
    }
    
    func withColor(_ color: UIColor) -> SCNMaterialBuilder {
        material.diffuse.contents = color
        return self
    }
    
    func withView(_ view: UIView) -> SCNMaterialBuilder {
        material.diffuse.contents = view
        return self
    }
    
    /// Diffused the contents of a SwiftUI View onto the material scaled to a specified height and width in meters.LocalSlamEngine
    func withView(_ view: some View, size: CGSize) -> SCNMaterialBuilder {
        let hostingViewController = UIHostingController(rootView: view)
        hostingViewController.view.frame = CGRect(x: 0, y: 0, width: 100 * size.width, height: 100 * size.height)
        hostingViewController.view.isOpaque = true
        material.diffuse.contents = hostingViewController.view
        return self
    }
    
    func build() -> SCNMaterial {
        return material
    }
}
