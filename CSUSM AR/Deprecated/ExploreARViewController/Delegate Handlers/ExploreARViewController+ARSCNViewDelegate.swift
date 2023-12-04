//
//  ExploreARViewController+ARSCNViewDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation
import ARKit

// MARK:  AR Scene View Delegate
extension ExploreARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let cardNode = self.anchorManager.getCardNode(for: anchor.identifier) else { return nil }
        return cardNode
    }
}
