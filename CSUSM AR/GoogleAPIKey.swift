//
//  GoogleAPIKey.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/14/23.
//

import Foundation

enum GoogleAPI {
    
    static private let assertionFailureText = "Please review `Secrets.swift` file and ensure values have been set for `GoogleAPI`."
    
    case sandbox
    case production
    
    var apiKey: String {
        switch self {
        case .sandbox:
            guard let key = Secrets.GoogleAPI.SandboxGoogleAPIKey else { fatalError(GoogleAPI.assertionFailureText); }
            return key
        case .production:
            guard let key = Secrets.GoogleAPI.SandboxGoogleAPIKey else { fatalError(GoogleAPI.assertionFailureText) }
            return key
        }
    }
}
