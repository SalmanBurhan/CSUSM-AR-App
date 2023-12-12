//
//  UUID+VPropertyEncodable.swift
//
//
//

import Foundation

@_documentation(visibility:private)
extension UUID: VPropertyEncodable {
    public var vEncoded: String {
        uuidString
    }
}
