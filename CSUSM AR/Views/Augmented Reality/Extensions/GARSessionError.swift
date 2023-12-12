//
//  GARSessionError.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import ARCoreGARSession
import Foundation

/// An extension for the GARSessionError enum.
///
/// This extension provides a textual description for each error code in the GARSessionError enum.
extension GARSessionError {
  /// A textual description of the error.
  ///
  /// - Returns: A string representing the description of the error.
  var description: String {
    switch self.code {
    case .deviceNotCompatible:
      return "This device or OS version is not currently supported."
    case .invalidArgument:
      return "An unexpected input was passed to the session."
    case .notTracking:
      return "The session is not unable to track the surrounding environment."
    case .frameOutOfOrder:
      return "The session is has lost synchronization with the camera input."
    case .resourceExhausted:
      return "There are no available resources to continue with the session."
    case .locationPermissionNotGranted:
      return
        "The operation could not be completed because location permission was not granted with full accuracy."
    case .configurationNotSupported:
      return
        "The configuration for the session could not be set because it is unsupported on this device."
    case .illegalState:
      return
        "The operation could not be completed because the session entered an unpredictable state."
    default:
      return "An unexpected error occurred."
    }
  }
}
