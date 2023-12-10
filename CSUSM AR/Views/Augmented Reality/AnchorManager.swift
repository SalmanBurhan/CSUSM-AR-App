//
//  AnchorManager.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation

import ARCore
import ARKit

/// The AnchorManager class is responsible for managing anchors in the augmented reality scene.
class AnchorManager {
    /**
     A private property that represents a recursive lock used for thread synchronization.
     */
    private var lock = NSRecursiveLock()
    
    // Use a Dictionary to store the mappings between UUID pairs and associated values
    private var anchorMap: [UUIDPair: AnchorData] = [:]
    
    // Define a structure to represent a pair of UUIDs
    struct UUIDPair: Hashable {
        var arIdentifier: UUID
        var garIdentifier: UUID
    }
    
    // Define a structure to hold the associated data
    struct AnchorData {
        var arAnchor: ARAnchor
        var garAnchor: GARAnchor
        var location: Concept3DLocation
        var category: Concept3DCategory
        let cardNode: LocationNode
        
        /**
         Initializes an instance of AnchorManager with the provided parameters.
         
         - Parameters:
             - arAnchor: The ARAnchor associated with the anchor.
             - garAnchor: The GARAnchor associated with the anchor.
             - location: The Concept3DLocation associated with the anchor.
             - category: The Concept3DCategory associated with the anchor.
         */
        init(arAnchor: ARAnchor, garAnchor: GARAnchor, location: Concept3DLocation, category: Concept3DCategory) {
            self.arAnchor = arAnchor
            self.garAnchor = garAnchor
            self.location = location
            self.category = category
            self.cardNode = LocationNode(location, category, width: 12.19) /// 40 feet (12.19 meters)
        }
    }
    
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
        
        return anchorMap.filter { $0.key.arIdentifier == identifier || $0.key.garIdentifier == identifier }
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
    
    // Function to safely add anchors
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
        
        anchorMap = anchorMap.filter { $0.key.arIdentifier != identifier && $0.key.garIdentifier != identifier }
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
}
