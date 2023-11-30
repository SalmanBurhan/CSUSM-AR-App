//
//  AnchorBridge.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/29/23.
//

import Foundation
import ARCore

class UniversalAnchor {
    
    private let arAnchor: ARAnchor
    private let garAnchor: GARAnchor
    
    var name: String? { self.arAnchor.name }
    var transform: simd_float4x4 { self.garAnchor.transform }

    var identifier: UUID { self.arAnchor.identifier }
    var garIdentifier: UUID { self.garAnchor.identifier }
    
    var trackingState: GARTrackingState { self.garAnchor.trackingState }
    var hasValidTransform: Bool { self.garAnchor.trackingState == .tracking }
    
    init(garAnchor: GARAnchor, arAnchor: ARAnchor?) {
        self.arAnchor = arAnchor ?? ARAnchor(transform: garAnchor.transform)
        self.garAnchor = garAnchor
    }
    
    convenience init(garAnchor: GARAnchor) {
        self.init(garAnchor: garAnchor, arAnchor: nil)
    }    
}
