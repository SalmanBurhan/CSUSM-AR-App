//
//  VEncodable.swift
//
//
//

/// Represents something that can be encoded
/// in a format like V or vCard.
@_documentation(visibility:private)
public protocol VEncodable {
    /// The encoded string in the format.
    var vEncoded: String { get }
}
