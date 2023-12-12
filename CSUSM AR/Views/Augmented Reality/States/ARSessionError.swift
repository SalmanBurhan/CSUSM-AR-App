//
//  ARSessionError.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import ARCore
import Foundation

/// An enumeration representing different errors that can occur during an AR session.
///
/// - `garSessionError`: An error specific to the GARSession.
/// - `vpsUnavailable`: The Visual Positioning Service (VPS) is not available at the current location.
/// - `unexpected`: An unexpected error occurred.
enum ARSessionError: Error, LocalizedError {

  /// Represents an error that can occur during an AR session.
  /// - Parameter sessionError: The specific error that occurred during the AR session.
  case garSessionError(_ sessionError: GARSessionError)

  /// Represents an error state in the AR session when the virtual positioning system (VPS) is unavailable.
  case vpsUnavailable

  /// Represents an unexpected error that occurred during an AR session.
  /// - Parameter error: The error that occurred.
  case unexpected(_ error: Error)

  /// A computed property that returns the description of the ARSessionError.
  var description: String {
    switch self {
    case .garSessionError(let sessionError):
      sessionError.description
    case .unexpected(let error):
      "An unexpected error occurred: \(error.localizedDescription)"
    case .vpsUnavailable:
      """
      Visual Positioning Service (VPS) is not available at your current location. \
      Location data may not be as accurate.
      """
    }
  }
}
