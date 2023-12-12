//
//  GARRooftopAnchorState.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import ARCoreGeospatial
import Foundation

/// An extension for the GARRooftopAnchorState enum.
///
/// This extension adds a computed property `description` to the `GARRooftopAnchorState` enum, which returns a textual description of the state.
///
/// The possible values for `GARRooftopAnchorState` are:
/// - `.none`: Represents the state when there is no anchor.
/// - `.success`: Represents the state when the anchor is successfully created.
/// - `.errorInternal`: Represents an internal error while creating the anchor.
/// - `.errorNotAuthorized`: Represents the state when the user is not authorized to create the anchor.
/// - `.errorUnsupportedLocation`: Represents the state when the location is not supported for creating the anchor.
/// - `.unknown`: Represents an unknown state.
extension GARRooftopAnchorState {
  /// A textual description of the state.
  var description: String {
    switch self {
    case .none: return "None"
    case .success: return "Success"
    case .errorInternal: return "Error Internal"
    case .errorNotAuthorized: return "Not Authorized"
    case .errorUnsupportedLocation: return "Unsupported Location"
    default: return "Unknown"
    }
  }
}
