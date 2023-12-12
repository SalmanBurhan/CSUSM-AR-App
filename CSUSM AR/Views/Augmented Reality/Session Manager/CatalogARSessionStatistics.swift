//
//  CatalogARSessionStatistics.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/3/23.
//

import Foundation

/// Represents the statistics of an AR session in the catalog.
struct CatalogARSessionStatistics {
  /// Indicates whether an error occurred during the AR session.
  let error: Bool

  /// The error message associated with the AR session, if any.
  let errorMessage: String?

  /// The accuracy of the location data in meters, if available.
  let locationAccuracy: Double?

  /// The accuracy of the altitude data in meters, if available.
  let altitudeAccuracy: Double?

  /// The accuracy of the orientation data in meters, if available.
  let orientationAccuracy: Double?

  /// A formatted string representation of the location accuracy.
  var locationAccuracyString: String {
    guard let accuracy = self.locationAccuracy else {
      return "Unknown\nLocation Accuracy"
    }
    return String(format: "%.2fm\nLocation Accuracy", accuracy)
  }

  /// A formatted string representation of the altitude accuracy.
  var altitudeAccuracyString: String {
    guard let accuracy = self.altitudeAccuracy else {
      return "Unknown\nAltitude Accuracy"
    }
    return String(format: "%.2fm\nAltitude Accuracy", accuracy)
  }

  /// A formatted string representation of the orientation accuracy.
  var orientationAccuracyString: String {
    guard let accuracy = self.orientationAccuracy else {
      return "Unknown\nDirection Accuracy"
    }
    return String(format: "%.2fm\nCompass Direction Accuracy", accuracy)
  }

  /// A formatted string representation of the error message.
  var errorMessageString: String {
    guard let message = self.errorMessage else {
      return "Unknown Error"
    }
    return String(format: "Error: %s", message)
  }

  /// Initializes a new instance of `CatalogARSessionStatistics` with the specified accuracy values.
  /// - Parameters:
  ///   - locationAccuracy: The accuracy of the location data in meters.
  ///   - altitudeAccuracy: The accuracy of the altitude data in meters.
  ///   - orientationAccuracy: The accuracy of the orientation data in meters.
  init(locationAccuracy: Double, altitudeAccuracy: Double, orientationAccuracy: Double) {
    self.error = false
    self.errorMessage = nil
    self.locationAccuracy = locationAccuracy
    self.altitudeAccuracy = altitudeAccuracy
    self.orientationAccuracy = orientationAccuracy
  }

  /// Initializes a new instance of `CatalogARSessionStatistics` with the specified error message.
  /// - Parameter errorMessage: The error message associated with the AR session.
  init(errorMessage: String) {
    self.error = true
    self.errorMessage = errorMessage
    self.locationAccuracy = nil
    self.altitudeAccuracy = nil
    self.orientationAccuracy = nil
  }
}
