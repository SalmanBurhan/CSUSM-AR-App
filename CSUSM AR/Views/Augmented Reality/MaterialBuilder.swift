//
//  MaterialBuilder.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/29/23.
//

import SceneKit
import SwiftUI
import UIKit

/// A builder class for creating SCNMaterial objects.
///
/// Use `SCNMaterialBuilder` to conveniently create and configure `SCNMaterial` objects for use in SceneKit.
///
/// Example usage:
/// ``` swift
/// let blueMaterial = SCNMaterialBuilder()
///     .withColor(.blue)
///     .build()
/// ```
///
/// ``` swift
/// let someView = UIView()
/// let viewMaterial = SCNMaterialBuilder()
///    .withView(someView)
///   .build()
/// ```
struct SCNMaterialBuilder {

  /// The SCNMaterial object being built.
  private var material: SCNMaterial

  /// Initializes a new instance of SCNMaterialBuilder.
  init() {
    self.material = SCNMaterial()
    self.material.locksAmbientWithDiffuse = true
  }

  /// Sets the color of the material.
  /// - Parameter color: The color to set.
  /// - Returns: The updated SCNMaterialBuilder instance.
  func withColor(_ color: UIColor) -> SCNMaterialBuilder {
    material.diffuse.contents = color
    return self
  }

  /// Sets the contents of the material to a UIView.
  /// - Parameter view: The view to set as the contents.
  /// - Returns: The updated SCNMaterialBuilder instance.
  func withView(_ view: UIView) -> SCNMaterialBuilder {
    material.diffuse.contents = view
    return self
  }

  /// Sets the contents of the material to a SwiftUI View, scaled to a specified size.
  /// - Parameters:
  ///   - view: The SwiftUI view to set as the contents.
  ///   - size: The size to scale the view to, in meters.
  /// - Returns: The updated SCNMaterialBuilder instance.
  func withView(_ view: some View, size: CGSize) -> SCNMaterialBuilder {
    let hostingViewController = UIHostingController(rootView: view)
    hostingViewController.view.frame = CGRect(
      x: 0, y: 0, width: 100 * size.width, height: 100 * size.height)
    hostingViewController.view.isOpaque = true
    material.diffuse.contents = hostingViewController.view
    return self
  }

  /// Builds and returns the SCNMaterial object.
  /// - Returns: The built SCNMaterial object.
  func build() -> SCNMaterial {
    return material
  }
}
