//
//  RooftopState.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import Foundation
import ARCore

extension GARRooftopAnchorState {
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
