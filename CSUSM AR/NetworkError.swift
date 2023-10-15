//
//  NetworkError.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import Foundation

enum NetworkError: Error {
    case invalidData
    case invalidURL
    case invalidResponseCode(Int)
    case requestFailed
}
