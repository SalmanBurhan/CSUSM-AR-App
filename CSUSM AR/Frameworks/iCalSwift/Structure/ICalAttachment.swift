//
//  ICalAttachment.swift
//  
//
//

import Foundation

/// This property provides the capability to associate a
/// document object with a calendar component.
///
/// See https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.1.1
@_documentation(visibility:private)
public struct ICalAttachment: VPropertyEncodable {
    public var parameters: [ICalParameter]
    public var value: String
    
    public var vEncoded: String {
        value
    }
    
    public init(parameters: [ICalParameter], value: String) {
        self.parameters = parameters
        self.value = value
    }
}
