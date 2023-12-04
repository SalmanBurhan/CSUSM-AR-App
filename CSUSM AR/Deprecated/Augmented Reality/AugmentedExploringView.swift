//
//  WayfindingView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/5/23.
//

import SwiftUI
import ARKit

struct AugmentedRealityView: View {
    
    var locationManager = LocationManager.shared
    
    var body: some View {
        Group{
            if !locationManager.isAuthorized {
                LocationServicesPermissionsView(self.locationManager)
            } else {
                AugmentedExploringView()
            }
        }.onAppear(perform: {
            self.locationManager.checkPermissions()
        })
    }
}

struct LocationServicesPermissionsView: View {
    
    let locationManager: LocationManager
    
    init(_ manager: LocationManager) {
        self.locationManager = manager
    }
    
    var body: some View {
        self.locationManager.viewForAuthorizationStatus()
    }
}

struct AugmentedExploringView: UIViewControllerRepresentable {
    typealias UIViewControllerType = AugmentedExploringViewController

    func makeUIViewController(context: Context) -> AugmentedExploringViewController {
        return AugmentedExploringViewController()
    }
    
    func updateUIViewController(_ uiViewController: AugmentedExploringViewController, context: Context) {
        
    }
}
