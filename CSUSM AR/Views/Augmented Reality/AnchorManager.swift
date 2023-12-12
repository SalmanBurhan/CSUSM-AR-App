//
//  AnchorManager.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import ARCore
import ARKit
import Foundation

/// The AnchorManager class is responsible for managing anchors in the augmented reality scene.
///
/// Use the AnchorManager class to add, remove, and update anchors in the AR scene. Anchors are used to position virtual content in the real world.
class AnchorManager {

  /// A private property that represents a recursive lock used for thread synchronization.
  private var lock = NSRecursiveLock()

  // Use a Dictionary to store the mappings between UUID pairs and associated values
  private var anchorMap: [UUIDPair: AnchorData] = [:]

  /**
     Retrieves all anchors and their corresponding data.

     - Returns: A dictionary containing the `UUIDPair` and their associated `AnchorData`.
     */
  func getAnchors() -> [UUIDPair: AnchorData] {
    lock.lock()
    defer { lock.unlock() }
    return self.anchorMap
  }

  /**
     Retrieves the anchors associated with the specified identifier.

     - Parameters:
         - identifier: The unique identifier of the anchors. This may be either an ARAnchorIdentifier or a GARAnchorIdentifier.

     - Returns: An array of AnchorData objects representing the anchors.
     */
  func getAnchors(for identifier: UUID) -> [AnchorData] {
    lock.lock()
    defer { lock.unlock() }

    return anchorMap.filter {
      $0.key.arIdentifier == identifier || $0.key.garIdentifier == identifier
    }
    .map { $0.value }
  }

  /**
     Retrieves the anchor data for the specified AR identifier and GAR identifier.

     - Parameters:
         - arIdentifier: The UUID of the AR identifier.
         - garIdentifier: The UUID of the GAR identifier.

     - Returns: An optional `AnchorData` object containing the anchor data, or `nil` if no anchor data is found.
     */
  func getAnchors(arIdentifier: UUID, garIdentifier: UUID) -> AnchorData? {
    lock.lock()
    defer { lock.unlock() }

    let pair = UUIDPair(arIdentifier: arIdentifier, garIdentifier: garIdentifier)
    return anchorMap[pair]
  }

  /** Adds anchors to the anchor manager.
      - Parameters:
          - uuidPair: The UUID pair associated with the anchors.
          - data: The anchor data to be added.
    */
  func addAnchors(uuidPair: UUIDPair, data: AnchorData) {
    lock.lock()
    defer { lock.unlock() }

    anchorMap[uuidPair] = data
  }

  /**
     Removes anchors associated with the given identifier.
     - Parameter identifier: The identifier of the anchors to be removed. This may be either an ARAnchorIdentifier or a GARAnchorIdentifier.
     */
  func removeAnchors(for identifier: UUID) {
    lock.lock()
    defer { lock.unlock() }

    anchorMap = anchorMap.filter {
      $0.key.arIdentifier != identifier && $0.key.garIdentifier != identifier
    }
  }

  /**
     Removes all anchors from the anchor manager.
     */
  func removeAllAnchors() {
    lock.lock()
    defer { lock.unlock() }

    anchorMap.removeAll()
  }

  /**
     Retrieves the location associated with the given identifier.

     - Parameters:
         - identifier: The unique identifier of the location. This may be either an ARAnchorIdentifier or a GARAnchorIdentifier.

     - Returns: The Concept3DLocation object associated with the identifier, or nil if no location is found.
     */
  func getLocation(for identifier: UUID) -> Concept3DLocation? {
    return self.getAnchors(for: identifier).first?.location
  }

  /**
     Retrieves the location node associated with the specified identifier.

     - Parameters:
         - identifier: The unique identifier of the location node. This may be either an ARAnchorIdentifier or a GARAnchorIdentifier.

     - Returns: The location node associated with the specified identifier, or nil if no such node exists.
     */
  func getCardNode(for identifier: UUID) -> LocationNode? {
    return self.getAnchors(for: identifier).first?.cardNode
  }

  // MARK: - UUIDPair

  /// A structure that represents a pair of UUIDs.
  ///
  /// This structure is used to store a pair of UUIDs, one for ARKit anchors and one for game anchors.
  /// It conforms to the `Hashable` protocol, allowing instances of `UUIDPair` to be used as keys in dictionaries.
  struct UUIDPair: Hashable {

    /// The UUID for ARKit anchors.
    var arIdentifier: UUID

    /// The UUID for game anchors.
    var garIdentifier: UUID

    /**
     Initializes an instance of UUIDPair with the provided parameters.

      - Parameters:
        - arIdentifier: The UUID for ARKit anchors.
        - garIdentifier: The UUID for game anchors.
      */
    init(arIdentifier: UUID, garIdentifier: UUID) {
      self.arIdentifier = arIdentifier
      self.garIdentifier = garIdentifier
    }
  }

  // MARK: - Anchor Data

  /// A struct that represents the data for an anchor.
  ///
  /// This struct is used to store the data associated with an anchor,
  /// including the AR anchor, the GAR anchor, the location, the category,
  /// and the node representing the location in the augmented reality scene.
  struct AnchorData {

    /// The AR anchor associated with the anchor manager.
    var arAnchor: ARAnchor

    /// The GAR anchor associated with the anchor manager.
    var garAnchor: GARAnchor

    /// The location associated with the anchor manager.
    var location: Concept3DLocation

    /// The category associated with the anchor manager.
    var category: Concept3DCategory

    /// The node representing the location in the augmented reality scene.
    let cardNode: LocationNode

    /**
         Initializes an instance of AnchorManager with the provided parameters.

         - Parameters:
             - arAnchor: The ARAnchor associated with the anchor.
             - garAnchor: The GARAnchor associated with the anchor.
             - location: The Concept3DLocation associated with the anchor.
             - category: The Concept3DCategory associated with the anchor.
         */
    init(
      arAnchor: ARAnchor, garAnchor: GARAnchor, location: Concept3DLocation,
      category: Concept3DCategory
    ) {
      self.arAnchor = arAnchor
      self.garAnchor = garAnchor
      self.location = location
      self.category = category
      self.cardNode = LocationNode(location, category, width: 12.19)/// 40 feet (12.19 meters)
    }
  }
}
