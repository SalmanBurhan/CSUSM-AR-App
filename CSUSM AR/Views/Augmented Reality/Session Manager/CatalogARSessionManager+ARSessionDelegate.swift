//
//  CatalogARSessionManager+ARSessionDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/1/23.
//

import ARKit

/// An extension of `CatalogARSessionManager` that conforms to the `ARSessionDelegate` protocol.
extension CatalogARSessionManager: ARSessionDelegate {

  /**
     Called when a new frame is available from the AR session.

     - Parameters:
        - session: The AR session that produced the frame.
        - frame: The updated AR frame.

     This method is an implementation of the `ARSessionDelegate` protocol's `session(_:didUpdate:)` method.
     It is called whenever a new frame is available from the AR session.

     The method performs the following tasks:
     1. Updates the anchors in the scene with the updated frame.
     2. Updates the localization state and statistics.
     3. Updates the transform of the card nodes in the scene.

     The transform of each card node is updated based on the anchor's transform and the user's point of view.
     This ensures that the card node is always facing the user.
     */
  public func session(_ session: ARSession, didUpdate frame: ARFrame) {
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
