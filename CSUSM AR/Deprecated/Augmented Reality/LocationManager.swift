//
//  LocationManager.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/12/23.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

class LocationManager: NSObject {
    
    static let shared = LocationManager()
    
    private var manager: CLLocationManager
    
    @objc dynamic var isAuthorized: Bool = false
    @objc dynamic var lastLocation: CLLocation?
    
    override init() {
        /// Set Initial Values
        self.manager = CLLocationManager()
        super.init()
        
        self.manager.delegate = self
        self.checkPermissions()
    }
    
    func startMonitoring() {
        self.manager.startUpdatingLocation()
    }
    
    func stopMonitoring() {
        self.manager.stopUpdatingLocation()
    }
    
    func viewForAuthorizationStatus() -> some View {
        
        var title: String
        var systemImage: String
        var description: String
        var button: Button<Text>
        
        switch self.manager.authorizationStatus {
        case .notDetermined:
            
            title = "Enable Location Services"
            systemImage = "location.circle"
            description = """
            In order to determine the location of your device relative to the buildings around you, \
            the app needs permission to access your current location while using the app.\n\n \
            For the best and most accurate user experience, it is important to enable \
            Precise Location access.
            """
            button = Button("Enable Precise Location Access", action: {
                self.manager.requestWhenInUseAuthorization()
            })

        case .restricted, .denied:
            /// The app's access to location services has been restricted or denied by the user.
            
            title = "Location Services Restricted"
            systemImage = "location.slash.circle"
            description = """
            In order to determine the location of your device relative to the buildings around you, \
            the app needs permission to access your current location while using the app.\n\n\
            Location Services appear to be disabled or restricted. Please enable Precise When In Use Access.
            """
            button = Button("Change Location Permissions", action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            })
            
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            /// The app's access to location services has been allowed.
            if self.manager.accuracyAuthorization == .fullAccuracy {
                title = ""
                systemImage = ""
                description = ""
                button = Button("", action: {})
            }
            
            title = "Location Services Accuracy Reduced"
            systemImage = "location.circle"
            description = """
            In order to determine the location of your device relative to the buildings around you, \
            the app needs permission to access your current location while using the app.\n\n\
            Precise Accuracy appears to be disabled. Please enable Precise When In Use Access.
            """
            button = Button("Change Location Permissions", action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            })
                        
        @unknown default:
            title = ""
            systemImage = ""
            description = ""
            button = Button("", action: {})
        }
        
        
        return ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            button.buttonStyle(.borderedProminent).controlSize(.large)
        }

    }
    
    func checkPermissions() {
        switch self.manager.authorizationStatus {
        
        case .notDetermined:
            /// It is likely that that the user has not yet been prompted to grant location services access.
            /// The app is responsible for obtaining the location permission prior to configuring the ARCore
            /// session. ARCore will not cause the location permission system prompt.
            
            self.isAuthorized = false
            print("It is likely that that the user has not yet been prompted to grant location services access.")
            
        case .restricted, .denied:
            /// The app's access to location services has been restricted or denied by the user.
            ///
            self.isAuthorized = false
            print("The app's access to location services has been restricted or denied by the user.")
        
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            /// The app's access to location services has been allowed.

            if self.manager.accuracyAuthorization == .fullAccuracy {
                self.isAuthorized = true
            } else {
                self.isAuthorized = false
                print("The app has not been granted full precision access to location services.")
            }
            
        @unknown default:
            fatalError("An Unexpected CLAuthorizationStatus was received by checkPermissions() handler.")
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.isAuthorized = (manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse) && (manager.accuracyAuthorization == .fullAccuracy)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager - Error - \(error.localizedDescription)")
    }
}
