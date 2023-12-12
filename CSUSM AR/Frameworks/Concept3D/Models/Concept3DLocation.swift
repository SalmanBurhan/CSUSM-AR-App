//
//  Concept3DLocation.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import CoreLocation
import Foundation

/// A struct representing a location in the Concept3D framework.
///
/// This struct conforms to the `Decodable` and `Identifiable` protocols.
/// It contains properties that describe the location, such as its ID, category ID, altitude, map ID, floors, mark ID, name, and reference.
/// The `location` property represents the coordinates of the location using the `CLLocationCoordinate2D` struct.
/// The `details` property contains additional details about the location, if available.
///
/// This struct provides an initializer to create a `Concept3DLocation` instance with default values.
/// It also provides a custom initializer to decode a `Concept3DLocation` instance from a decoder.
/// The `copy(with:)` method allows creating a copy of the `Concept3DLocation` instance with updated details.
///
/// Example usage:
/// ``` swift
/// let location = Concept3DLocation(id: 1, categoryId: 2, altitude: 0, map: 3, floors: [1, 2, 3], markId: 4, name: "Location", reference: "Ref", location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
/// let updatedLocation = location.copy(with: details)
/// ```
///
/// ``` swift
/// let data = Data()
/// let decoder = JSONDecoder()
/// let location = try? decoder.decode(Concept3DLocation.self, from: data)
/// ```
///
/// - Note: The `altitude` property appears to always return zero from the server side.
/// - Note: The `categoryId` property is represented as `catId` in the JSON response.
/// - Note: The `map` property is represented as `mapId` in the JSON response.
/// - Note: The `floors` property is represented as `level` in the JSON response.
/// - Note: The `markId` property is represented as `mrkId` in the JSON response.
struct Concept3DLocation: Decodable, Identifiable {

  /// The ID of the location.
  let id: Int

  /// The ID of the category the location belongs to.
  ///
  /// - Note: This property is represented as `catId` in the JSON response.
  let categoryId: Int

  /// The altitude of the location.
  ///
  /// - Note: This property appears to always return zero from the server side.
  let altitude: Double

  /// The ID of the map the location belongs to.
  ///
  /// - Note: This property is represented as `mapId` in the JSON response.
  let map: Int

  /// The list of floors the location belongs to.
  ///
  /// - Note: This property is represented as `level` in the JSON response.
  let floors: [Int]

  /// The ID of the mark the location belongs to.
  let markId: Int

  /// The name of the location.
  let name: String

  /// The reference of the location.
  ///
  /// - Note: This property is represented as `ref` in the JSON response.
  var reference: String

  /// The coordinates of the location.
  ///
  /// - Note: This property is represented as `lat` and `lng` in the JSON response.
  var location: CLLocationCoordinate2D

  /// The details of the location.
  /// - Important: This property is only set when the location is created using the `copy(with:)` method.
  var details: Concept3DLocationDetails?

  /// Coding keys used for decoding purposes.
  enum CodingKeys: String, CodingKey {
    case id
    case categoryId = "catId"
    case altitude
    case map = "mapId"
    case floors = "level"
    case markId = "mrkId"
    case name
    case reference

    case latitude = "lat"
    case longitude = "lng"

  }

  /// Creates a new instance of `Concept3DLocation`.
  ///
  /// This initializer is used to create a new instance of `Concept3DLocation`.
  /// It sets the initial values for the `id`, `categoryId`, `altitude`, `map`, `floors`, `markId`, `name`, `reference`, and `location` properties.
  ///
  /// - Parameters:
  ///  - id: The unique identifier of the location. Default value is -1.
  /// - categoryId: The identifier of the category the location belongs to. Default value is -1.
  /// - altitude: The altitude of the location. Default value is -1.
  /// - map: The identifier of the map the location belongs to. Default value is -1.
  /// - floors: The list of floors the location belongs to. Default value is an empty array.
  /// - markId: The identifier of the mark the location belongs to. Default value is -1.
  /// - name: The name of the location. Default value is an empty string.
  /// - reference: The reference of the location. Default value is an empty string.
  /// - location: The coordinates of the location. Default value is an empty `CLLocationCoordinate2D` instance.
  init(
    id: Int = -1,
    categoryId: Int = -1,
    altitude: Double = -1,
    map: Int = -1,
    floors: [Int] = [],
    markId: Int = -1,
    name: String = "",
    reference: String = "",
    location: CLLocationCoordinate2D = .init()
  ) {
    self.id = id
    self.categoryId = categoryId
    self.altitude = altitude
    self.map = map
    self.floors = floors
    self.markId = markId
    self.name = name
    self.reference = reference
    self.location = location
  }

  /// Creates a new instance of `Concept3DLocation` by decoding it from a decoder.
  /// - Parameter decoder: The decoder to read data from.
  /// - Throws: An error if the data read from the decoder is corrupted or otherwise invalid.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decode(Int.self, forKey: .id)
    self.categoryId = try container.decode(Int.self, forKey: .categoryId)
    self.altitude = try container.decode(Double.self, forKey: .altitude)
    self.map = try container.decode(Int.self, forKey: .map)
    self.floors = try container.decode([Int].self, forKey: .floors)
    self.markId = try container.decode(Int.self, forKey: .markId)
    self.name = try container.decode(String.self, forKey: .name)
    self.reference = try container.decode(String.self, forKey: .reference)

    self.location = CLLocationCoordinate2D(
      latitude: try container.decode(Double.self, forKey: .latitude),
      longitude: try container.decode(Double.self, forKey: .longitude)
    )
  }

  /// Creates a copy of the `Concept3DLocation` instance with updated details.
  /// - Parameter details: The details to update the copy with.
  /// - Returns: A copy of the `Concept3DLocation` instance with updated details.
  func copy(with details: Concept3DLocationDetails) -> Self {
    var copy = self
    copy.details = details
    return copy
  }
}
