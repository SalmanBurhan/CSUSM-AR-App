//
//  Date+VPropertyEncodable.swift
//  
//
//

import Foundation

@_documentation(visibility:private)
extension Date: VPropertyEncodable {
    public var vEncoded: String {
        ICalDateTime(type: .dateTime, date: self, tzid: nil).vEncoded
    }
}
