//
//  CatalogARSessionManager+ARSCNViewDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import ARKit

/// This extension conforms to the `ARSCNViewDelegate` protocol and provides additional functionality for the `CatalogARSessionManager` class.
extension CatalogARSessionManager: ARSCNViewDelegate {

  /**
     Returns a node for the specified AR anchor.

     This method is called by the ARSCNViewDelegate to retrieve a node for rendering the specified AR anchor in the scene.

     - Parameters:
        - renderer: The scene renderer that is rendering the scene.
        - anchor: The AR anchor for which to provide a node.

     - Returns: A SCNNode object representing the visual representation of the AR anchor, or nil if the anchor is not a card anchor.
     */
  public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    guard let cardNode = self.anchorManager.getCardNode(for: anchor.identifier) else { return nil }
    return cardNode
  }

}
