//
//  LocationCategory.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation

struct LocationCategory: Codable {
    
    let id: Int
    let name: String
    let parentCategory: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "catId"
        case name
        case parentCategory = "parent"
    }
    
    init(id: Int = -1,
         name: String = "",
         parentCategory: Int = 0) {
        self.id = id
        self.name = name
        self.parentCategory = parentCategory
    }
}
