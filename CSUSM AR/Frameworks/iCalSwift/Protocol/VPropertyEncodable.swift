//
//  VPropertyEncodable.swift
//
//
//

/// Represents something that can be encoded in
/// a format like V, but may require
/// additional parameters in the content line.
@_documentation(visibility:private)
public protocol VPropertyEncodable: VEncodable {
    /// The additional parameters.
    var parameters: [ICalParameter] { get }
}

@_documentation(visibility:private)
public extension VPropertyEncodable {
    var parameters: [ICalParameter] { [] }
    
    func parameter(_ key: String) -> ICalParameter? {
        parameters.first(where: { $0.key == key })
    }
}
