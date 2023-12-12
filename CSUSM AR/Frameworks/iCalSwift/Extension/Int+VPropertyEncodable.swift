//
//  Int+VPropertyEncodable.swift
//
//
//

@_documentation(visibility:private)
extension Int: VPropertyEncodable {
    public var vEncoded: String {
        String(self)
    }
}
