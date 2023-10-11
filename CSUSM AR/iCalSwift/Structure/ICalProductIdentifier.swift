//
//  ICalProductIdentifier.swift
//  
//
//

import Foundation

/// The identifier for the product that created the
/// iCalendar object.
///
/// See https://tools.ietf.org/html/rfc5545#section-3.7.3
public struct ICalProductIdentifier: VPropertyEncodable {
    public let segments: [String]

    public var vEncoded: String {
        "-\(segments.map { "//\($0)" }.joined())"
    }

    //TODO add UUID
    public init(segments: [String] = ["calendar", "iCalSwift", "EN"]) {
        self.segments = segments
    }
}
