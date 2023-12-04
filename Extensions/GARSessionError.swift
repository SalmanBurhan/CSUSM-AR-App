//
//  GARSessionError.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import Foundation
import ARCore

extension GARSessionError {
    var description: String {
        switch self.code {
        case .deviceNotCompatible:
            "This device or OS version is not currently supported."
        case .invalidArgument:
            "An unexpected input was passed to the session."
        case .notTracking:
            "The session is not unable to track the surrounding environment."
        case .frameOutOfOrder:
            "The session is has lost synchronization with the camera input."
        case .resourceExhausted:
            "There are no available resources to continue with the session."
        case .locationPermissionNotGranted:
            "The operation could not be completed because location permission was not granted with full accuracy"
        case .configurationNotSupported:
            "The configuration for the session could not be set because it is unsupported on this device"
        case .illegalState:
            "The operation could not be completed because the session entered an unpredictable state."
        default:
            "An unexpected error occurred."
        }
    }
}
