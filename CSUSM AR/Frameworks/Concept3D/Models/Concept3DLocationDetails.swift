//
//  Concept3DLocationDetails.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import CoreLocation
import Foundation

/// A struct representing the details of a Concept3D location.
///
/// This struct conforms to the `Decodable` protocol, allowing it to be decoded from JSON data.
/// It contains properties for the location's ID, description, and images.
/// The `images` property is a dictionary that maps `Concept3DImageSize` enum values to `URL` values.
/// The struct also provides initializers for creating instances with default values, and a custom initializer for decoding from a `Decoder`.
struct Concept3DLocationDetails: Decodable {

  /// The ID of the location.
  let id: Int

  /// The description of the location.
  let description: String

  /// The images associated with the location.
  var images: [Concept3DImageSize: URL]

  /// Coding keys used for decoding purposes.
  private enum CodingKeys: String, CodingKey {
    case id
    case description
    case mediaLinks = "mediaUrls"
  }

  /// Initializes a `Concept3DLocationDetails` instance with the specified values.
  ///
  /// - Parameters:
  ///   - id: The ID of the location. Default value is -1.
  ///   - description: The description of the location. Default value is an empty string.
  ///   - images: The images associated with the location. Default value is an empty dictionary.
  init(id: Int = -1, description: String = "", images: [Concept3DImageSize: URL] = [:]) {
    self.id = id
    self.description = description
    self.images = images
  }

  /// Initializes a `Concept3DLocationDetails` instance by decoding from a `Decoder`.
  ///
  /// - Parameter decoder: The decoder to use for decoding the JSON data.
  /// - Throws: An error if the decoding fails.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decode(Int.self, forKey: .id)
    self.description = try container.decode(String.self, forKey: .description)

    let mediaLinks = try container.decode([String].self, forKey: .mediaLinks)
    if let mediaLink = mediaLinks.first {
      self.images = [
        .tiny: try Concept3D.imageURL(mediaLink, ofSize: .tiny, scaled: false),
        .small: try Concept3D.imageURL(mediaLink, ofSize: .small, scaled: false),
        .medium: try Concept3D.imageURL(mediaLink, ofSize: .medium, scaled: false),
        .large: try Concept3D.imageURL(mediaLink, ofSize: .large, scaled: false),
        .xlarge: try Concept3D.imageURL(mediaLink, ofSize: .xlarge, scaled: false),
        .xxlarge: try Concept3D.imageURL(mediaLink, ofSize: .xlarge, scaled: false),
      ]
    } else {
      self.images = [Concept3DImageSize: URL]()
    }
  }
}
