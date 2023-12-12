//
//  Concept3DCategory.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation

/// Represents a category response from the Concept3D framework.
struct Concept3DCategoryResponse: Decodable {

  /// The main category.
  let category: Concept3DCategory?

  /// The list of subcategories.
  let categories: [Concept3DCategory]

  /// The list of locations.
  let locations: [Concept3DLocation]

  ///
  /// A private enumeration representing the coding keys for the root level of the Concept3DCategory model.
  ///
  /// - `children`: The coding key for the "children" property.
  ///
  private enum RootCodingKeys: String, CodingKey {
    case children
  }

  ///
  /// A private enumeration representing the coding keys for the children level of the Concept3DCategory model.
  ///
  /// - `categories`: The coding key for the "categories" property.
  /// - `locations`: The coding key for the "locations" property.
  ///
  private enum ChildrenCodingKeys: String, CodingKey {
    case categories
    case locations
  }

  /// Initializes a new instance of `Concept3DCategoryResponse` by decoding the data from the given decoder.
  /// - Parameter decoder: The decoder to use for decoding the data.
  /// - Throws: An error if the decoding fails.
  init(from decoder: Decoder) throws {
    let rootContainer = try decoder.container(keyedBy: RootCodingKeys.self)
    let childrenContainer = try rootContainer.nestedContainer(
      keyedBy: ChildrenCodingKeys.self, forKey: .children)

    var categories = [Concept3DCategory]()
    if var categoriesContainer = try? childrenContainer.nestedUnkeyedContainer(forKey: .categories)
    {
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
    self.locations = locations.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })

    if var categoryContainer = try? decoder.unkeyedContainer() {
      self.category = try categoryContainer.decodeIfPresent(Concept3DCategory.self)
    } else {
      self.category = nil
    }
  }
}

/// Represents a category in the Concept3D framework.
///
/// This struct conforms to the `Decodable` and `Identifiable` protocols.
/// It contains properties that represent the attributes of a category, such as its ID, name, parent category, icon URL, locations, and children.
/// The `Concept3DCategory` struct also provides an initializer and a custom `CodingKeys` enum for decoding purposes.
///
/// Usage:
/// ```
/// let category = Concept3DCategory(id: 1, name: "Category 1", parentCategory: 0)
/// print(category.name) // Output: "Category 1"
/// ```
///
/// - Note: The `singleSelect` and `weight` properties are file-private and used for internal purposes only.
/// - Important: The `iconURL` property can be `nil` if the category does not have an associated icon.
///
/// - SeeAlso: `Concept3DLocation`, `Concept3D.imageURL(iconPath:)`
///
struct Concept3DCategory: Decodable, Identifiable {

  // MARK: File Private level Coding Keys.

  /// File Private level Coding Keys used soley for internal decoding purposes.
  fileprivate let singleSelect: Int

  /// File Private level Coding Keys used soley for internal decoding purposes.
  fileprivate let weight: Int

  // MARK:  Public level Coding Keys.

  /// The ID of the category.
  let id: Int

  /// The name of the category.
  let name: String

  /// The ID of the parent category.
  let parentCategory: Int

  /// The URL of the icon associated with the category.
  var iconURL: URL?

  /// The list of locations associated with the category.
  var locations: [Concept3DLocation]?

  /// The list of subcategories associated with the category.
  var children: [Concept3DCategory]?

  /// Represents a category in the Concept3D framework.
  ///
  /// This initializer is used to create a new instance of `Concept3DCategory`.
  /// It sets the initial values for the `id`, `name`, `parentCategory`, `singleSelect`, and `weight` properties.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the category. Default value is -1.
  ///   - name: The name of the category. Default value is an empty string.
  ///   - parentCategory: The identifier of the parent category. Default value is 0.
  ///
  init(id: Int = -1, name: String = "", parentCategory: Int = 0) {
    self.id = id
    self.name = name
    self.parentCategory = parentCategory

    /// File Private level Coding Keys used solely for internal purposes.
    self.singleSelect = 0
    self.weight = 0
  }

  /**
 Enum defining the coding keys for the `Concept3DCategory` model.

 The coding keys are used to map the properties of the `Concept3DCategory` model to their corresponding keys in the JSON representation.

 - id: The unique identifier of the category.
 - name: The name of the category.
 - parentCategory: The parent category of the category.
 - listIcon: The icon used for the category in the list view.
 - singleSelect: A file private coding key used for internal purposes.
 - weight: A file private coding key used for internal purposes.
 */
  enum CodingKeys: String, CodingKey {

    case id = "catId"
    case name
    case parentCategory = "parent"
    case listIcon

    /// File Private level Coding Keys used solely for internal purposes.
    case singleSelect
    case weight

  }

  /**
 Initializes a `Concept3DCategory` object from a decoder.

 - Parameters:
     - decoder: The decoder to read data from.

 - Throws: An error if the decoding process fails.

 - Returns: An initialized `Concept3DCategory` object.
 */
  init(from decoder: Decoder) throws {
    let container: KeyedDecodingContainer<Concept3DCategory.CodingKeys> = try decoder.container(
      keyedBy: Concept3DCategory.CodingKeys.self)

    self.id = try container.decode(Int.self, forKey: Concept3DCategory.CodingKeys.id)
    self.name = try container.decode(String.self, forKey: Concept3DCategory.CodingKeys.name)
    self.parentCategory = try container.decode(
      Int.self, forKey: Concept3DCategory.CodingKeys.parentCategory)
    self.singleSelect = try container.decode(
      Int.self, forKey: Concept3DCategory.CodingKeys.singleSelect)
    self.weight = try container.decode(Int.self, forKey: Concept3DCategory.CodingKeys.weight)
    self.iconURL = try Concept3D.imageURL(
      iconPath: try container.decode(String.self, forKey: Concept3DCategory.CodingKeys.listIcon))
  }

}
