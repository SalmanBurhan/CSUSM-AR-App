//
//  ExploreARViewController+ARSessionDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation
import ARKit

// MARK:  AR Session Delegate
extension ExploreARViewController: ARSessionDelegate {
 
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let garSession = self.garSession,
              let updatedGARFrame = try? garSession.update(frame)
        else {
            print("Error Updating GARFrame.")
            self.updateLocalizationState()
            return
        }
        
        self.garFrame = updatedGARFrame
        self.updateLocalizationState()
        self.updateTrackingState()
        updatedGARFrame.updatedAnchors.forEach({
            guard $0.hasValidTransform else { return }
            self.anchorManager.getAnchors(for: $0.identifier).first?.cardNode.updateTransform(
                $0.transform, withScalingFromPOV: self.scnView.pointOfView)
        })
    }
    
}
