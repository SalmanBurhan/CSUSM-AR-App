//
//  Concept3DError.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/21/23.
//

import Foundation

enum Concept3DError: Error {
    case locationImageNotFound
    case locationImagePathInvalid
    case endpointResponseNotModelable
    case unexpectedStatusCode(_ httpStatusCode: Int)
    case mismatchedResponseData(_ decodingError: DecodingError)
    case unexpectedError
}

