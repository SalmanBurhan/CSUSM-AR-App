//
//  Bool+VPropertyEncodable.swift
//
//
//

@_documentation(visibility:private)
extension Bool: VPropertyEncodable {
    public var vEncoded: String {
        self ? "TRUE" : "FALSE"
    }
}
