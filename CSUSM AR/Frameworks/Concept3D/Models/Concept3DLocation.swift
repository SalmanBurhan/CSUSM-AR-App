//
//  Concept3DLocation.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation
import CoreLocation

struct Concept3DLocation: Decodable, Identifiable {
    
    let id: Int
    let categoryId: Int
    let altitude: Double /// Appears to always return zero from the server side.
    let map: Int
    let floors: [Int]
    let markId: Int
    let name: String
    var reference: String

    var location: CLLocationCoordinate2D
    var details: Concept3DLocationDetails?
    
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
    
    init(id: Int = -1,
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
    
    func copy(with details: Concept3DLocationDetails) -> Self {
        var copy = self
        copy.details = details
        return copy
    }
    
}

