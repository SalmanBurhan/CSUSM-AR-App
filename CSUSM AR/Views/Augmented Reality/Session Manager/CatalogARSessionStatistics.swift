//
//  CatalogARSessionStatistics.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/3/23.
//

import Foundation

struct CatalogARSessionStatistics {
    let error: Bool
    let errorMessage: String?
    let locationAccuracy: Double?
    let altitudeAccuracy: Double?
    let orientationAccuracy: Double?
    
    var locationAccuracyString: String {
        guard let accuracy = self.locationAccuracy
        else { return "Unknown\nLocation Accuracy" }
        return String(format: "%.2fm\nLocation Accuracy", accuracy)
    }

    var altitudeAccuracyString: String {
        guard let accuracy = self.altitudeAccuracy
        else { return "Unknown\nAltitude Accuracy" }
        return String(format: "%.2fm\nAltitude Accuracy", accuracy)
    }

    var orientationAccuracyString: String {
        guard let accuracy = self.orientationAccuracy
        else { return "Unknown\nDirection Accuracy" }
        return String(format: "%.2fm\nCompass Direction Accuracy", accuracy)
    }
    
    var errorMessageString: String {
        guard let message = self.errorMessage
        else { return "Unknown Error" }
        return String(format: "Error: %s", message)
    }

    init(locationAccuracy: Double, altitudeAccuracy: Double, orientationAccuracy: Double) {
        self.error = false
        self.errorMessage = nil
        self.locationAccuracy = locationAccuracy
        self.altitudeAccuracy = altitudeAccuracy
        self.orientationAccuracy = orientationAccuracy
    }
    
    init (errorMessage: String) {
        self.error = true
        self.errorMessage = errorMessage
        self.locationAccuracy = nil
        self.altitudeAccuracy = nil
        self.orientationAccuracy = nil
    }
}
