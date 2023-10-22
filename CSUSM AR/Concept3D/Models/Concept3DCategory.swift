//
//  Concept3DCategory.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation

struct Concept3DCategoryResponse: Decodable {
    
    let category: Concept3DCategory?
    let categories: [Concept3DCategory]
    let locations: [Concept3DLocation]
    
    private enum RootCodingKeys: String, CodingKey {
        case children
    }
    
    private enum ChildrenCodingKeys: String, CodingKey {
        case categories
        case locations
    }
    
    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootCodingKeys.self)
        let childrenContainer = try rootContainer.nestedContainer(keyedBy: ChildrenCodingKeys.self, forKey: .children)
        
        var categories = [Concept3DCategory]()
        if var categoriesContainer = try? childrenContainer.nestedUnkeyedContainer(forKey: .categories) {
            while !categoriesContainer.isAtEnd {
                if let category = try categoriesContainer.decodeIfPresent(Concept3DCategory.self) {
                    if category.singleSelect == 0 {
                        categories.append(category)
                    }
                }
            }
        }
        self.categories = categories.sorted(by: { $0.weight < $1.weight })
        
        var locations = [Concept3DLocation]()
        if var locationsContainer = try? childrenContainer.nestedUnkeyedContainer(forKey: .locations) {
            while !locationsContainer.isAtEnd {
                if let location = try locationsContainer.decodeIfPresent(Concept3DLocation.self) {
                    locations.append(location)
                }
            }
        }
        self.locations = locations.sorted(by: { $0.name.lowercased() < $1.name.lowercased()})
        
        if var categoryContainer = try? decoder.unkeyedContainer() {
            self.category = try categoryContainer.decodeIfPresent(Concept3DCategory.self)
        } else {
            self.category = nil
        }
    }

}

struct Concept3DCategory: Decodable, Identifiable {
    
    /// File Private level Coding Keys used soley for internal purposes.
    fileprivate let singleSelect: Int
    fileprivate let weight: Int

    /// Public level Coding Keys
    let id: Int
    let name: String
    let parentCategory: Int
    var iconURL: URL?
    
    var locations: [Concept3DLocation]?
    var children: [Concept3DCategory]?
    
    init(id: Int = -1, name: String = "", parentCategory: Int = 0) {
        self.id = id
        self.name = name
        self.parentCategory = parentCategory
        
        /// File Private level Coding Keys used soley for internal purposes.
        self.singleSelect = 0
        self.weight = 0
    }

    
    enum CodingKeys: String, CodingKey {
        
        case id = "catId"
        case name
        case parentCategory = "parent"
        case listIcon

        /// File Private level Coding Keys used soley for internal purposes.
        case singleSelect
        case weight

    }
    
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Concept3DCategory.CodingKeys> = try decoder.container(keyedBy: Concept3DCategory.CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: Concept3DCategory.CodingKeys.id)
        self.name = try container.decode(String.self, forKey: Concept3DCategory.CodingKeys.name)
        self.parentCategory = try container.decode(Int.self, forKey: Concept3DCategory.CodingKeys.parentCategory)
        self.singleSelect = try container.decode(Int.self, forKey: Concept3DCategory.CodingKeys.singleSelect)
        self.weight = try container.decode(Int.self, forKey: Concept3DCategory.CodingKeys.weight)
        self.iconURL = try Concept3D.imageURL(iconPath: try container.decode(String.self, forKey: Concept3DCategory.CodingKeys.listIcon))
    }

}
