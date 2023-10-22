//
//  Concept3DLocationDetails.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation
import CoreLocation

struct Concept3DLocationDetails: Decodable {

    let id: Int
    let description: String
    var images: [Concept3DImageSize: URL]

    private enum CodingKeys: String, CodingKey {
        case id
        case description
        case mediaLinks = "mediaUrls"
    }
    
    init(id: Int = -1, description: String = "", images: [Concept3DImageSize: URL] = [:]) {
        self.id = id
        self.description = description
        self.images = images
    }
    
    
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
                .xxlarge: try Concept3D.imageURL(mediaLink, ofSize: .xlarge, scaled: false)
            ]
        } else {
            self.images = [Concept3DImageSize: URL]()
        }
    }
    
}
