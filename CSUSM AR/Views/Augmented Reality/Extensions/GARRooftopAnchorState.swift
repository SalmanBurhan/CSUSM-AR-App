//
//  GARRooftopAnchorState.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation
import ARCoreGeospatial

/// An extension for the GARRooftopAnchorState enum.
extension GARRooftopAnchorState {
    /// A textual description of the state.
    var description: String {
        switch self {
        case .none: "None"
        case .success: "Success"
        case .errorInternal: "Error Internal"
        case .errorNotAuthorized: "Not Authorized"
        case .errorUnsupportedLocation: "Unsupported Location"
        default: "Unknown"
        }
    }
}
