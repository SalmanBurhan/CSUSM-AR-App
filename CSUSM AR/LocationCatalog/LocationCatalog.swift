//
//  LocationCatalog.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation

enum LocationCatalogError: Error {
    case locationImageNotFound
    case locationImagePathInvalid
    case endpointResponseNotModelable
    case unexpectedStatusCode(_ httpStatusCode: Int)
    case mismatchedResponseData
    case unexpectedError
}

class LocationCatalog {

    enum Endpoint {
        case locations
        case location(_ id: Int)
        case categories
        case image(location: String, width: Int, height: Int, scaled: Bool = true)
    }

    static func fetchLocations() async throws -> [Location] {
        return try await self.fetch(.locations)
    }
    
    static func fetchDetails(for location: Location) async throws -> LocationDetails {
        return try await self.fetch(.location(location.id))
    }
    
    static func fetchCategories() async throws -> [LocationCategory] {
        return try await self.fetch(.categories)
    }
    
    static func imageURL(for location: Location, ofSize size: (width: Int, height: Int), scaled: Bool = true) async throws -> URL {
        let locationDetails = try await location.details
        guard let imagePath = locationDetails.mediaLinks.first else { throw LocationCatalogError.locationImageNotFound }
        let url = try self.url(for: .image(location: imagePath, width: size.width, height: size.height, scaled: scaled))
        return url
        /*
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateStatusCode(for: response)
        guard (response.mimeType?.contains("image/") ?? false) == true else { throw LocationCatalogError.mismatchedResponseData}
        return data
         */
    }
}

extension LocationCatalog {
    private static func decode<T: Decodable>(model: T.Type, from data: Data) throws -> T {
        return try JSONDecoder().decode(model, from: data)
    }
    
    private static func validateStatusCode(for response: URLResponse) throws {
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw LocationCatalogError.unexpectedStatusCode (
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }
    }
    
    private static func url(for endpoint: Endpoint) throws -> URL {
        guard let key = Secrets.Concept3DAPI.key,
              let mapId = Secrets.Concept3DAPI.mapId,
              let baseURL = Secrets.Concept3DAPI.baseURL,
              let cmsBaseURL = Secrets.Concept3DAPI.cmsBaseURL
        else {
            fatalError("Please review `Secrets.swift` file and ensure values have been set for `Concept3DAPI`.")
        }
        switch endpoint {
        case .locations:
            return URL(string: "\(baseURL)/locations?map=\(mapId)&key=\(key)")!
        case .categories:
            return URL(string: "\(baseURL)/categories?map=\(mapId)&key=\(key)")!
        case .location(let id):
            return URL(string: "\(baseURL)/locations/\(id)?map=\(mapId)&key=\(key)")!
        case .image(let path, let width, let height, let scaled):
            guard let urlSafePath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            else { throw LocationCatalogError.locationImagePathInvalid }
            return URL(string: "\(cmsBaseURL)/map/lib/image-cache/i.php?mapId=\(mapId)&image=\(urlSafePath)&w=\(width)&h=\(height)&r=\(scaled ? 1 : 0)")!
        }
    }
    
    private static func model(for endpoint: Endpoint) throws -> Decodable.Type {
        switch endpoint {
        case .locations:
            return [Location].self
        case .categories:
            return [LocationCategory].self
        case .location(_):
            return LocationDetails.self
        case .image(_, _, _, _):
            throw LocationCatalogError.endpointResponseNotModelable
        }
    }
    
    private static func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        do {
            let url = try self.url(for: endpoint)
            let (data, response) = try await URLSession.shared.data(from: url)
            try self.validateStatusCode(for: response)
            return try JSONDecoder().decode(self.model(for: endpoint), from: data) as! T
        } catch is DecodingError {
            throw LocationCatalogError.mismatchedResponseData
        } catch {
            throw LocationCatalogError.unexpectedError
        }
    }
}
