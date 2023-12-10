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

/// A class that manages the location functionality for the augmented reality feature.
class LocationManager: NSObject {
        
    /**
     A class that manages the location updates using CLLocationManager.
     */
    private let manager: CLLocationManager

    /// A publisher that emits a boolean value indicating the authorization status for location services.
    let authorizationPublisher = CurrentValueSubject<Bool, Never>(false)
    /// A publisher that emits CLLocation objects representing the current location.
    let locationPublisher = PassthroughSubject<CLLocation, Never>()
        
    override init() {
        /// Set Initial Values
        self.manager = CLLocationManager()
        super.init()
        
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.delegate = self
    }
    
    deinit {
        self.manager.stopUpdatingLocation()
    }
    
    /**
        Starts monitoring the user's location.
    */
    func startMonitoring() {
        self.manager.startUpdatingLocation()
    }
    
    /**
     Stops monitoring the user's location.
     */
    func stopMonitoring() {
        self.manager.stopUpdatingLocation()
    }
    
    /**
     Returns a view for the authorization status of the location manager.
     
     - Returns: A view representing the authorization status.
     */
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
    
    /**
        Checks if the app is authorized to access the device's location.
     
        - Returns: A boolean value indicating whether the app is authorized to access the device's location.
    */
    @discardableResult
    func isAuthorized() -> Bool {
        switch self.manager.authorizationStatus {
        
        case .notDetermined:
            /// It is likely that that the user has not yet been prompted to grant location services access.
            /// The app is responsible for obtaining the location permission prior to configuring the ARCore
            /// session. ARCore will not cause the location permission system prompt.
            
            print("It is likely that that the user has not yet been prompted to grant location services access.")
            return false
            
        case .restricted, .denied:
            /// The app's access to location services has been restricted or denied by the user.

            print("The app's access to location services has been restricted or denied by the user.")
            return false
            
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            /// The app's access to location services has been allowed.

            if self.manager.accuracyAuthorization == .fullAccuracy {
                return true
            } else {
                print("The app has not been granted full precision access to location services.")
                return false
            }
            
        @unknown default:
            fatalError("An Unexpected CLAuthorizationStatus was received by checkPermissions() handler.")
        }
    }
}

/**
    This extension makes the `LocationManager` class conform to the `CLLocationManagerDelegate` protocol.
*/
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationPublisher.send(self.isAuthorized())
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else { return }
        self.locationPublisher.send(lastLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager - Error - \(error.localizedDescription)")
    }
}
