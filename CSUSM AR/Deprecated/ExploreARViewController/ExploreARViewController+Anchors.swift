//
//  ExploreARViewController+Anchors.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation
import ARCore

extension ExploreARViewController {
    
    
    // MARK: - BUILD ANCHORS FROM CATALOG
    
    /// **NOTE:**  You may resolve multiple anchors at a time, but a session **cannot be tracking more than 100 Rooftop or Terrain anchors at time**. Attempting to resolve more than 100 Rooftop or Terrain anchors will result in `GARSessionErrorCodeResourceExhausted`.
    func createAnchors(for locations: [Concept3DLocation]) {
        print("Creating Anchors for \(locations.count) Locations.")
        
        guard let eastUpSouthQTarget = self.garFrame?.earth?.cameraGeospatialTransform?.eastUpSouthQTarget else {
            print("Failed to build anchors due to invalid geospatial transform in the current GARFrame.")
            return
        }
        
        locations.forEach({ location in
            do {
                try self.garSession!.createAnchorOnRooftop(
                    coordinate: location.location,
                    altitudeAboveRooftop: 15.24,
                    eastUpSouthQAnchor: eastUpSouthQTarget,
                    completionHandler: { self.resolveAnchor($0, forLocation: location, withState: $1) })
            } catch let error {
                print("Error Adding Rooftop Anchor: \(error)")
            }
        })
    }
    
    func resolveAnchor(_ anchor: GARAnchor?, forLocation location: Concept3DLocation, withState state: GARRooftopAnchorState) {
        guard let garAnchor = anchor, garAnchor.hasValidTransform, state == .success else {
            print("Failed to resolve anchor for \(location.name)")
            print("State → \(state.description), Valid Transform → \(String(describing: anchor?.hasValidTransform))")
            return
        }
        let arAnchor = ARAnchor(transform: garAnchor.transform)
        let identifier = AnchorManager.UUIDPair(arIdentifier: arAnchor.identifier, garIdentifier: garAnchor.identifier)
        self.anchorManager.addAnchors(
            uuidPair: identifier,
            data: AnchorManager.AnchorData(arAnchor: arAnchor, garAnchor: garAnchor, location: location))
        self.arSession.add(anchor: arAnchor)
    }
}
