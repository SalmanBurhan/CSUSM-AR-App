//
//  ExploreARViewController+CLLocationManagerDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation
import CoreLocation

// MARK:  Core Location Manager Delegate
extension ExploreARViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("location manager did change authorization")
        self.checkLocationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // TODO: CHECK VPS POSITION AVAILABILITY
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error updating location: \(error)")
    }
}
