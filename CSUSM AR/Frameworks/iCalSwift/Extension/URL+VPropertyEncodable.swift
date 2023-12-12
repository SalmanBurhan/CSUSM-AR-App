//
//  URL+VPropertyEncodable.swift
//
//
//

import Foundation

@_documentation(visibility:private)
extension URL: VPropertyEncodable {
    public var vEncoded: String {
        absoluteString
    }
}
