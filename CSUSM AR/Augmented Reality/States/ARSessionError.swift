//
//  ARSessionError.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import Foundation
import ARCore

enum ARSessionError: Error, LocalizedError {
    
    case garSessionError(_ sessionError: GARSessionError)
    case vpsUnavailable
    case unexpected(_ error: Error)
    
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
