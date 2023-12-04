//
//  CatalogARSessionManager+ARSessionDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/1/23.
//

import ARKit

extension CatalogARSessionManager: ARSessionDelegate {
 
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let updatedAnchors = try? self.garSession?.update(frame).updatedAnchors
        self.updateLocalizationState()
        self.updateStatistics()
        updatedAnchors?.forEach({
            guard $0.hasValidTransform == true else { return }
            self.anchorManager.getAnchors(for: $0.identifier).first?.cardNode.updateTransform(
                    $0.transform, withScalingFromPOV: self.sceneView.pointOfView)
        })
    }
    
}
