//
//  Concept3DError.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/21/23.
//

import Foundation

/// An enumeration that represents different errors that can occur in the Concept3D framework.
enum Concept3DError: Error {
  /// The location image was not found.
  case locationImageNotFound

  /// The location image path is invalid.
  case locationImagePathInvalid

  /// The endpoint response cannot be converted to a model object.
  case endpointResponseNotModelable

  /// An unexpected HTTP status code was received.
  /// - Parameter httpStatusCode: The HTTP status code.
  case unexpectedStatusCode(_ httpStatusCode: Int)

  /// The response data does not match the expected format.
  /// - Parameter decodingError: The decoding error.
  case mismatchedResponseData(_ decodingError: DecodingError)

  /// An unexpected error occurred.
  case unexpectedError
}
