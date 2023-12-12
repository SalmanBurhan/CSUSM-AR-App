//
//  ICalSubTimeZone.swift
//  
//
//

import Foundation

/// Provide a grouping of component properties that defines a
/// time zone.
///
/// See https://tools.ietf.org/html/rfc5545#section-3.6.5
@_documentation(visibility:private)
public class ICalSubTimeZone: VComponent {
    public let component = Constant.Component.daylight
    
    /// This property specifies when the calendar component begins.
    ///
    /// See https://tools.ietf.org/html/rfc5545#section-3.8.2.4
    public var dtstart: Date
    
    /// This property specifies the offset that is in use in this
    /// time zone observance.
    ///
    /// See https://tools.ietf.org/html/rfc5545#section-3.8.3.4
    public var tzOffsetTo: String
    
    /// This property specifies the offset that is in use prior to
    /// this time zone observance.
    ///
    /// See https://tools.ietf.org/html/rfc5545#section-3.8.3.3
    public var tzOffsetFrom: String
    
    /// This property defines a rule or repeating pattern for
    /// recurring events, to-dos, journal entries, or time zone
    /// definitions.
    ///
    /// See https://tools.ietf.org/html/rfc5545#section-3.8.5.3
    public var rrule: ICalRRule?
    
    /// This property specifies the customary designation for a
    /// time zone description.
    ///
    /// See https://tools.ietf.org/html/rfc5545#section-3.8.3.2
    public var tzName: String?
    
    public var properties: [VContentLine?] {
        [
            .line(Constant.Prop.tzOffsetFrom, tzOffsetFrom),
            .line(Constant.Prop.rrule, rrule),
            .line(Constant.Prop.dtstart, dtstart),
            .line(Constant.Prop.tzName, tzName),
            .line(Constant.Prop.tzOffsetTo, tzOffsetTo)
        ]
    }
    
    public init(
        dtstart: Date,
        tzOffsetTo: String,
        tzOffsetFrom: String,
        rrule: ICalRRule? = nil,
        tzName: String? = nil
    ) {
        self.dtstart = dtstart
        self.tzOffsetTo = tzOffsetTo
        self.tzOffsetFrom = tzOffsetFrom
        self.rrule = rrule
        self.tzName = tzName
    }
}
