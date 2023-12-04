//
//  CatalogARView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/1/23.
//

import SwiftUI
import ARKit
import Combine

struct CatalogARView: View {
    
    // MARK: - PROPERTIES
    
    private var cancellables: Set<AnyCancellable> = []
    private var session = CatalogARSessionManager.shared
    @State private var hasLocationPermissions = false
    @State private var isVPSAvailable = false
    @State private var sessionStatistics: CatalogARSessionStatistics?

    init(_ locations: [Concept3DLocation] = []) {
        self.session.catalog = locations
    }
    
    var body: some View {
        VStack {
            if hasLocationPermissions {
                session
                    .sceneViewRepresentable
                    .overlay(session.coachingViewRepresentable)
                    .overlay(isVPSAvailable ? nil : vpsLimitedView())
                    .overlay(sessionStatistics != nil ? statisticsView() : nil)
                    .onAppear(perform: sceneDidAppear)
                    .onDisappear(perform: sceneDidDisappear)
            } else {
                session
                    .locationManager
                    .viewForAuthorizationStatus()
            }
        }
        .onReceive(session.locationManager.authorizationPublisher) { hasPermissions in
            print("Catalog AR View did receive change in Location Services authorization. | hasPermissions: \(hasPermissions)")
            self.hasLocationPermissions = hasPermissions
        }
        .onReceive(session.vpsPublisher) { isAvailable in
            print("Catalog AR View did receive change in VPS availability. | isAvailable: \(isAvailable)")
            self.isVPSAvailable = isAvailable
        }
        .onReceive(session.statisticsPublisher) { statistics in
            self.sessionStatistics = statistics
        }
    }
        
    func sceneDidAppear() {
        print("SceneView did disappear")
        session.run()
    }
    
    func sceneDidDisappear() {
        print("SceneView did disappear")
        session.pause()
    }
    
    @ViewBuilder
    func vpsLimitedView() -> some View {
        VStack {
            Text("Visual Positioning (VPS) unavailable. Relying soley on GPS data.")
                .font(.caption)
                .opacity(0.8)
            Spacer()
        }
    }
    
    @ViewBuilder
    func statisticsView() -> some View {
        if let statistics = self.sessionStatistics {
            VStack {
                Spacer()
                HStack {
                    if statistics.error {
                        Text(statistics.errorMessageString)
                            .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
                    } else {
                        Text(statistics.locationAccuracyString)
                            .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
                        Spacer()
                        Text(statistics.altitudeAccuracyString)
                            .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
                        Spacer()
                        Text(statistics.orientationAccuracyString)
                            .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
                    }
                }.padding([.leading, .trailing], 5)
            }
        }
        else { EmptyView() }
    }
}

#Preview {
    CatalogARView()
}
