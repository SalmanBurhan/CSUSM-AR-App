//
//  Concept3DEndpoint.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/21/23.
//

import Foundation

/// Represents the endpoints for the Concept3D API.
enum Concept3DEndpoint {
  /// Endpoint for retrieving all locations.
  case locations

  /// Endpoint for retrieving a specific location by its ID.
  /// - Parameter id: The ID of the location.
  case location(_ id: Int)

  /// Endpoint for retrieving categories for a specific location.
  /// - Parameter id: The ID of the location.
  case categories(_ id: Int)

  /// Endpoint for retrieving a CMS image with the specified path, width, and height.
  /// - Parameters:
  ///   - path: The path of the image.
  ///   - width: The width of the image.
  ///   - height: The height of the image.
  ///   - scaled: Indicates whether the image should be scaled. Default value is `true`.
  case cmsImage(path: String, width: Int, height: Int, scaled: Bool = true)

  /// Endpoint for retrieving an icon image with the specified path.
  /// - Parameter path: The path of the image.
  case iconImage(path: String)
}
