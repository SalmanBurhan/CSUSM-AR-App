//
//  Concept3D.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation

/// A class representing the Concept3D framework.
///
/// This class is responsible for managing the locations and categories in the Concept3D framework.
/// It provides methods for fetching category details, retrieving image URLs, and fetching location details.
///
/// - Note: This class is an `ObservableObject`, allowing it to be used to trigger UI updates.
/// - Important: This class is a singleton, and can only be accessed using the `shared` property.
///              This is to ensure that only one instance of the class is created and data is able
///              to be reused across the app, reducing the number of recurring network requests.
class Concept3D: ObservableObject {

  /// The shared instance of the Concept3D class.
  static let shared = Concept3D()

  /// The array of Concept3DLocation objects.
  @Published var locations: [Concept3DLocation]

  /// The array of Concept3DCategory objects.
  @Published var categories: [Concept3DCategory]

  /// Initializes a new instance of the Concept3D class.
  ///
  /// - Parameters:
  ///   - locations: An optional array of Concept3DLocation objects. Default is an empty array.
  ///   - categories: An optional array of Concept3DCategory objects. Default is an empty array.
  internal init(locations: [Concept3DLocation] = [], categories: [Concept3DCategory] = []) {

    self.locations = locations
    self.categories = categories

    Task {
      do {
        let categoryResponse = try await Concept3D.fetchCategory(id: 0)
        self.categories = categoryResponse.categories
      } catch {
        print(error)
      }
    }
  }

  /// Fetches the category details for the specified category ID.
  ///
  /// - Parameter id: The ID of the category to fetch. Default is 0.
  /// - Returns: A `Concept3DCategoryResponse` object containing the category details.
  static func fetchCategory(id: Int = 0) async throws -> Concept3DCategoryResponse {
    return try await self.fetch(.categories(id))
  }

  /// Retrieves the image URL for the specified media link and image size.
  ///
  /// - Parameters:
  ///   - mediaLink: The media link of the image.
  ///   - size: The desired size of the image.
  ///   - scaled: A flag indicating whether the image should be scaled. Default is `true`.
  /// - Returns: The URL of the image.
  static func imageURL(_ mediaLink: String, ofSize size: Concept3DImageSize, scaled: Bool = true)
    throws -> URL
  {
    let url = try self.url(
      for: .cmsImage(
        path: mediaLink, width: size.resolution.width, height: size.resolution.height,
        scaled: scaled))
    return url
  }

  /// Retrieves the image URL for the specified icon path.
  ///
  /// - Parameter iconPath: The path of the icon image.
  /// - Returns: The URL of the icon image.
  static func imageURL(iconPath: String) throws -> URL {
    return try Concept3D.url(for: .iconImage(path: iconPath))
  }

  /// Fetches the details for the specified category.
  ///
  /// - Parameter category: The category for which to fetch the details.
  /// - Returns: A tuple containing the children categories and locations associated with the category.
  func fetchDetails(for category: Concept3DCategory) async throws -> (
    children: [Concept3DCategory], locations: [Concept3DLocation]
  ) {
    let response = try await Concept3D.fetchCategory(id: category.id)
    return (response.categories, response.locations)
  }

  /// Fetches the details for the specified location.
  ///
  /// - Parameter location: The location for which to fetch the details.
  /// - Returns: The details of the location.
  func fetchDetails(for location: Concept3DLocation) async throws -> Concept3DLocationDetails {
    return try await Concept3D.fetch(.location(location.id))
  }

}

// MARK: - Generic Abstraction for Data Requests

extension Concept3D {

  /// Decodes a given model model from provided data.
  /// - Parameters:
  ///   - model: `struct` conforming to `Decodable` protocol, `Codable` protocol optional but not required.
  ///   - data: response data received from `URLSession`.
  /// - Returns: response data decoded to fit the provided model.
  private static func decode<T: Decodable>(model: T.Type, from data: Data) throws -> T {
    return try JSONDecoder().decode(model, from: data)
  }

  /// Validates a `URLResponse` to ensure a HTTP response code of 200 `OK`.
  /// - Parameter response: `URLResponse` returned from a given `URLSession`.
  /// - Throws: `Concept3DError.unexpectedSatusCode`
  private static func validateStatusCode(for response: URLResponse) throws {
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw Concept3DError.unexpectedStatusCode(
        (response as? HTTPURLResponse)?.statusCode ?? -1
      )
    }
  }

  /// Builds a `URL` for an endpoint with parameters mapped to their respective url query names.
  /// - Parameter endpoint: a `Concept3DEndpoint` route populated with relevant parameters.
  /// - Returns: an unwrapped URL.
  /// - Throws: `Concept3DError.locationImagePathInvalid`
  private static func url(for endpoint: Concept3DEndpoint) throws -> URL {
    guard let key = Secrets.Concept3DAPI.key,
      let mapId = Secrets.Concept3DAPI.mapId,
      let baseURL = Secrets.Concept3DAPI.baseURL,
      let cmsBaseURL = Secrets.Concept3DAPI.cmsBaseURL,
      let assetBaseURL = Secrets.Concept3DAPI.assetBaseURL
    else {
      fatalError(
        "Please review `Secrets.swift` file and ensure values have been set for `Concept3DAPI`.")
    }
    switch endpoint {
    case .locations:
      return URL(string: "\(baseURL)/locations?map=\(mapId)&key=\(key)")!
    case .categories(let id):
      return URL(string: "\(baseURL)/categories/\(id)?children&map=\(mapId)&key=\(key)")!
    case .location(let id):
      return URL(string: "\(baseURL)/locations/\(id)?map=\(mapId)&key=\(key)")!
    case .cmsImage(let path, let width, let height, let scaled):
      guard let urlSafePath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      else { throw Concept3DError.locationImagePathInvalid }
      return URL(
        string:
          "\(cmsBaseURL)/map/lib/image-cache/i.php?mapId=\(mapId)&image=\(urlSafePath)&w=\(width)&h=\(height)&r=\(scaled ? 1 : 0)"
      )!
    case .iconImage(let assetPath):
      return URL(string: "\(assetBaseURL)\(assetPath)")!
    }
  }

  /// Computes the respective data model for a given endpoint route.
  /// - Parameter endpoint: A `Concept3DEndpoint` route.
  /// - Returns: A `Decodable` data model type.
  /// - Throws: `Concept3DError.endpointResponseNotModelable`
  private static func model(for endpoint: Concept3DEndpoint) throws -> Decodable.Type {
    switch endpoint {
    case .locations:
      return [Concept3DLocation].self
    case .categories(_):
      return Concept3DCategoryResponse.self
    case .location(_):
      return Concept3DLocationDetails.self
    case .cmsImage(_, _, _, _), .iconImage(_):
      throw Concept3DError.endpointResponseNotModelable
    }
  }

  /// Fetches and decodes the model for data received from the url created for a given `Concept3DEndpoint` route.
  /// - Parameter endpoint: A `Concept3DEndpoint` route.
  /// - Returns: A decoded data model.
  /// - Throws: `Concept3DError`
  private static func fetch<T: Decodable>(_ endpoint: Concept3DEndpoint) async throws -> T {
    do {
      let url = try self.url(for: endpoint)
      let (data, response) = try await URLSession.shared.data(from: url)
      try self.validateStatusCode(for: response)
      return try JSONDecoder().decode(self.model(for: endpoint), from: data) as! T
    } catch let error as DecodingError {
      throw Concept3DError.mismatchedResponseData(error)
    } catch let error as Concept3DError {
      throw error
    }
  }
}
