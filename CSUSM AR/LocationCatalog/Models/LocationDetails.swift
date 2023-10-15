//
//  LocationDetails.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation
import CoreLocation

struct LocationDetails: Codable {

    let id: Int
    let description: String
    let mediaLinks: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case description
        case mediaLinks = "mediaUrls"
    }
    
    init(id: Int = -1, description: String = "", mediaLinks: [String] = []) {
        self.id = id
        self.description = description
        self.mediaLinks = mediaLinks
    }
}
