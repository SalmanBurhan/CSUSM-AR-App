//
//  Location.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation
import CoreLocation

struct Location: Codable {
    
    let id: Int
    let categoryId: Int
    let altitude: Double
    let map: Int
    let floors: [Int]
    let markId: Int
    let name: String
    let reference: String
    
    private let latitude, longitude: Double
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var details: LocationDetails {
        get async throws {
            try await LocationCatalog.fetchDetails(for: self)
        }
    }
    
    var imageURL: URL?
    mutating func buildImageURL() async throws {
        self.imageURL = try await LocationCatalog.imageURL(for: self, ofSize: (width: 100, height: 120))
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "catId"
        case altitude
        case latitude = "lat"
        case longitude = "lng"
        case map = "mapId"
        case floors = "level"
        case markId = "mrkId"
        case name
        case reference
    }
    
    init(id: Int = -1,
         categoryId: Int = -1,
         altitude: Double = -1,
         map: Int = -1,
         floors: [Int] = [],
         markId: Int = -1,
         name: String = "",
         reference: String = "",
         latitude: Double = -1,
         longitude: Double = -1) {
        self.id = id
        self.categoryId = categoryId
        self.altitude = altitude
        self.map = map
        self.floors = floors
        self.markId = markId
        self.name = name
        self.reference = reference
        self.latitude = latitude
        self.longitude = longitude
    }
}

