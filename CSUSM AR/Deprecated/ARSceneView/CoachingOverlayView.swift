//
//  ARCoachingOverlay.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import SwiftUI
import ARKit

struct CoachingOverlayView: UIViewRepresentable {
    
    let arSession: ARSession
    let coachingOverlay = ARCoachingOverlayView()
    
    func makeUIView(context: Context) -> ARCoachingOverlayView {
        coachingOverlay.session = self.arSession
        coachingOverlay.activatesAutomatically = false
        coachingOverlay.goal = .tracking
        return coachingOverlay
    }
    
    func updateUIView(_ uiView: ARCoachingOverlayView, context: Context) { }
    
    func activate() {
        self.coachingOverlay.setActive(true, animated: true)
    }
    
    func deactivate() {
        self.coachingOverlay.setActive(false, animated: true)
    }
}
