//
//  CatalogARSessionManager+ARSessionDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/1/23.
//

import ARKit

extension CatalogARSessionManager: ARSessionDelegate {
 
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        /// Update the anchors in the scene with the updated frame.
        let updatedAnchors = try? self.garSession?.update(frame).updatedAnchors
        /// Update the localization state and statistics.
        self.updateLocalizationState()
        self.updateStatistics()
        /// Update the transform of the card nodes in the scene.
        updatedAnchors?.forEach({
            /// Check if the anchor has a valid transform. If not, return.
            guard $0.hasValidTransform == true else { return }
            /// Update the transform of the card node.
            /// The scaling is done with respect to the user's point of view.
            /// This ensures that the card node is always facing the user.
            self.anchorManager.getAnchors(for: $0.identifier).first?.cardNode.updateTransform(
                    $0.transform, withScalingFromPOV: self.sceneView.pointOfView)
        })
    }
    
}
