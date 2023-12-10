//
//  Concept3D.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation

class Concept3D: ObservableObject {

    static let shared = Concept3D()
    
    @Published var locations: [Concept3DLocation]
    @Published var categories: [Concept3DCategory]

    internal init(locations: [Concept3DLocation] = [], categories: [Concept3DCategory] = []) {
        
        self.locations = locations
        self.categories = categories
        
        Task {
//            if let locations = try? await Concept3D.fetchLocations() {
//                self.locations = locations
//            }
            do {
                let categoryResponse = try await Concept3D.fetchCategory(id: 0)
                self.categories = categoryResponse.categories
            } catch {
                print(error)
            }
//            if let categories = try? await Concept3D.fetchCategories() {
//                self.categories = categories
//            }
        }
    }
    
//    static func fetchLocations() async throws -> [Concept3DLocation] {
//        return try await withThrowingTaskGroup(of: (Concept3DLocation, Concept3DLocationDetails?).self) { group in
//            (try await self.fetch(.locations) as [Concept3DLocation]).forEach { location in
//                group.addTask {
//                    //print("Task - Utility - Fetching Details For \(location.id)")
//                    return await (location, try? Concept3D.fetchDetails(for: location))
//                }
//            }
//            
//            return try await group.reduce(into: []) { arr, result in
//                var location = result.0
//                location.details = result.1
//                location.imageURL = try? Concept3D.imageURL(for: location, ofSize: (width: 100, height: 120))
//                arr.append(location)
//            }
//            
//        }
//        
//    }
    
    static func fetchCategory(id: Int = 0) async throws -> Concept3DCategoryResponse {
        return try await self.fetch(.categories(id))
    }
        
    static func imageURL(_ mediaLink: String, ofSize size: Concept3DImageSize, scaled: Bool = true) throws -> URL {
        let url = try self.url(for: .cmsImage(path: mediaLink, width: size.resolution.width, height: size.resolution.height, scaled: scaled))
        return url
    }
    
    static func imageURL(iconPath: String) throws -> URL {
        return try Concept3D.url(for: .iconImage(path: iconPath))
    }
    
    func fetchDetails(for category: Concept3DCategory) async throws -> (children: [Concept3DCategory], locations: [Concept3DLocation]) {
        let response = try await Concept3D.fetchCategory(id: category.id)
        return (response.categories, response.locations)
    }
    
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
            throw Concept3DError.unexpectedStatusCode (
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
            fatalError("Please review `Secrets.swift` file and ensure values have been set for `Concept3DAPI`.")
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
            return URL(string: "\(cmsBaseURL)/map/lib/image-cache/i.php?mapId=\(mapId)&image=\(urlSafePath)&w=\(width)&h=\(height)&r=\(scaled ? 1 : 0)")!
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
