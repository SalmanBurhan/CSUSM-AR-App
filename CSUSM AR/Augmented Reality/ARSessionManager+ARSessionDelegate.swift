//
//  ARSessionManager+ARSessionDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/12/23.
//

import Foundation
import ARKit

extension ARSessionManager: ARSessionDelegate {
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        do {
            if let garFrame = try garSession?.update(frame) {
                self.currentGARFrame = garFrame
                
                if garSession?.currentFramePair?.garFrame.earth?.cameraGeospatialTransform != nil {
                    sessionReadyCondition.lock()
                    sessionReady = true
                    sessionReadyCondition.signal()
                    sessionReadyCondition.unlock()
                }
                latestGARAnchors = garFrame.anchors
                if let cameraGeospatialTransform = garFrame.earth?.cameraGeospatialTransform {
                    let _ = cameraGeospatialTransform.coordinate
                    if cameraGeospatialTransform.horizontalAccuracy < 1.2 {
                        self.geospatialAccuracy = .veryHigh
                    } else if cameraGeospatialTransform.horizontalAccuracy < 3.0 {
                        self.geospatialAccuracy = .high
                    } else if cameraGeospatialTransform.horizontalAccuracy < 8.0 {
                        self.geospatialAccuracy = .moderate
                    } else {
                        self.geospatialAccuracy = .low
                    }
                }
                for geometry in garFrame.streetscapeGeometries ?? [] {
                    if geometry.type == .building {
                        self.renderingHelper.renderStreetscapeMesh(geometries: geometry, color: .cyan)
                    } else {
                        self.renderingHelper.renderStreetscapeMesh(geometries: geometry, color: .black)
                    }
                }

            }

            // don't use Cloud Anchors if we have localized with the ARWorldMap
//            if localization != .withARWorldMap, let gAnchors = currentGARFrame?.anchors {
//                checkForCloudAnchorAlignment(anchors: gAnchors)
//            }
        } catch {
            print("couldn't update GAR Frame: \(error)")
        }
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case.limited(let reason):
            print("ARSession - Camera Did Change Tracking State - Limited State - Reason: \(reason)")
        case .normal:
            print("ARSession - Camera Did Change Tracking State - Normal State")
        case .notAvailable:
            print("ARSession - Camera Did Change Tracking State - State Not Available")
        }
    }
}
