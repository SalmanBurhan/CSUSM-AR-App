//
//  AnchorManager.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation

import ARCore
import ARKit

class AnchorManager {
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
        //let cardNode: CardNode
        //let cardNode: CustomNode
        let cardNode: LocationNode
        
        init(arAnchor: ARAnchor, garAnchor: GARAnchor, location: Concept3DLocation, category: Concept3DCategory) {
            self.arAnchor = arAnchor
            self.garAnchor = garAnchor
            self.location = location
            self.category = category
            //self.cardNode = CardNode(text: location.name)
            self.cardNode = LocationNode(location, category, width: 12.19) /// 40 feet (12.19 meters)
        }
    }
    
    // Function to safely access the data structure using one UUID
    func getAnchors(for identifier: UUID) -> [AnchorData] {
        lock.lock()
        defer { lock.unlock() }
        
        return anchorMap.filter { $0.key.arIdentifier == identifier || $0.key.garIdentifier == identifier }
            .map { $0.value }
    }
    
    // Function to safely access the data structure using two UUIDs
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
    
    // Function to safely remove anchors by UUID
    func removeAnchors(for identifier: UUID) {
        lock.lock()
        defer { lock.unlock() }
        
        anchorMap = anchorMap.filter { $0.key.arIdentifier != identifier && $0.key.garIdentifier != identifier }
    }
    
    func removeAllAnchors() {
        lock.lock()
        defer { lock.unlock() }
        
        anchorMap.removeAll()
    }
    
    func getLocation(for identifier: UUID) -> Concept3DLocation? {
        return self.getAnchors(for: identifier).first?.location
    }
    
//    func getCardNode(for identifier: UUID) -> CardNode? {
//        return self.getAnchors(for: identifier).first?.cardNode
//    }

    //    func getCardNode(for identifier: UUID) -> CustomNode? {
    //        return self.getAnchors(for: identifier).first?.cardNode
    //    }
    
    func getCardNode(for identifier: UUID) -> LocationNode? {
        return self.getAnchors(for: identifier).first?.cardNode
    }
}
