//
//  ICalRRule.swift
//  
//
//

import Foundation

/// This value type is used to identify properties that contain
/// a recurrence rule specification.
///
/// See https://tools.ietf.org/html/rfc5545#section-3.3.10
public struct ICalRRule: VPropertyEncodable {
    
    /// The frequency of the recurrence.
    public var frequency: Frequency
          
    /// At which interval the recurrence repeats (in terms of the frequency).
    /// E.g. 1 means every hour for an hourly rule, ...
    /// The default value is 1.
    public var interval: Int?

    /// The end date/time. Must have the same 'ignoreTime'-value as dtstart.
    public var until: ICalDateTime? {
        willSet {
            if newValue != nil {
                count = nil
            }
        }
    }
    
    /// The number of recurrences.
    public var count: Int? {
        willSet {
            if newValue != nil {
                until = nil
            }
        }
    }

    /// At which seconds of the minute it should occur.
    /// Must be between 0 and 60 (inclusive).
    public var bySecond: [Int]? {
        didSet { assert(bySecond?.allSatisfy { (0...60).contains($0) } ?? true, "by-second rules must be between 0 and 60 (inclusive): \(bySecond ?? [])") }
    }
    
    /// At which minutes of the hour it should occur.
    /// Must be between 0 and 60 (exclusive).
    public var byMinute: [Int]? {
        didSet { assert(byMinute?.allSatisfy { (0..<60).contains($0) } ?? true, "by-hour rules must be between 0 and 60 (exclusive): \(byMinute ?? [])") }
    }
    
    /// At which hours of the day it should occur.
    /// Must be between 0 and 24 (exclusive).
    public var byHour: [Int]? {
        didSet { assert(byHour?.allSatisfy { (0..<24).contains($0) } ?? true, "by-hour rules must be between 0 and 24 (exclusive): \(byHour ?? [])") }
    }
    
    /// At which days (of the week/year) it should occur.
    public var byDay: [Day]?
    
    /// At which days of the month it should occur. Specifies a COMMA-separated
    /// list of days of the month. Valid values are 1 to 31 or -31 to -1.
    public var byDayOfMonth: [Int]? {
        didSet { assert(byDayOfMonth?.allSatisfy { (1...31).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 31 or -31 and -1: \(byDayOfMonth ?? [])") }
    }
    
    /// At which days of the year it should occur. Specifies a list of days
    /// of the year.  Valid values are 1 to 366 or -366 to -1.
    public var byDayOfYear: [Int]? {
        didSet { assert(byDayOfYear?.allSatisfy { (1...366).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 366 or -366 and -1: \(byDayOfYear ?? [])") }
    }
    
    /// At which weeks of the year it should occur. Specificies a list of
    /// ordinals specifying weeks of the year. Valid values are 1 to 53 or -53 to
    /// -1.
    public var byWeekOfYear: [Int]? {
        didSet { assert(byWeekOfYear?.allSatisfy { (1...53).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 53 or -53 and -1: \(byWeekOfYear ?? [])") }
    }
    
    /// At which months it should occur.
    /// Must be between 1 and 12 (inclusive).
    public var byMonth: [Int]? {
        didSet { assert(byMonth?.allSatisfy { (1...12).contains($0) } ?? true, "by-month-of-year rules must be between 1 and 12: \(byMonth ?? [])") }
    }
    
    /// Specifies a list of values that corresponds to the nth occurrence within
    /// the set of recurrence instances specified by the rule. By-set-pos
    /// operates on a set of recurrence instances in one interval of the
    /// recurrence rule. For example, in a weekly rule, the interval would be one
    /// week A set of recurrence instances starts at the beginning of the
    /// interval defined by the frequency rule part. Valid values are 1 to 366 or
    /// -366 to -1. It MUST only be used in conjunction with another by-xxx rule
    /// part.
    public var bySetPos: [Int]? {
        didSet { assert(bySetPos?.allSatisfy { (1...366).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 366 or -366 and -1: \(bySetPos ?? [])") }
    }
    
    /// The day on which the workweek starts.
    /// Monday by default.
    public var startOfWorkweek: DayOfWeek?

    private var properties: [(String, [VEncodable]?)] {
        [
            (Constant.Prop.frequency, [frequency]),
            (Constant.Prop.interval, interval.map { [$0] }),
            (Constant.Prop.until, until.map { [$0] }),
            (Constant.Prop.count, count.map { [$0] }),
            (Constant.Prop.bySecond, bySecond),
            (Constant.Prop.byMinute, byMinute),
            (Constant.Prop.byHour, byHour),
            (Constant.Prop.byDay, byDay),
            (Constant.Prop.byDayOfMonth, byDayOfMonth),
            (Constant.Prop.byDayOfYear, byDayOfYear),
            (Constant.Prop.byWeekOfYear, byWeekOfYear),
            (Constant.Prop.byMonth, byMonth),
            (Constant.Prop.bySetPos, bySetPos),
            (Constant.Prop.startOfWorkweek, startOfWorkweek.map { [$0] })
        ]
    }

    public var vEncoded: String {
        properties.compactMap { (key, values) in
            values.map { "\(key)=\($0.map(\.vEncoded).joined(separator: ","))" }
        }.joined(separator: ";")
    }

    public enum Frequency: String, VEncodable {
        case secondly = "SECONDLY"
        case minutely = "MINUTELY"
        case hourly = "HOURLY"
        case daily = "DAILY"
        case weekly = "WEEKLY"
        case monthly = "MONTHLY"
        case yearly = "YEARLY"

        public var vEncoded: String { rawValue }
    }

    public enum DayOfWeek: String, VEncodable {
        case monday = "MO"
        case tuesday = "TU"
        case wednesday = "WE"
        case thursday = "TH"
        case friday = "FR"
        case saturday = "SA"
        case sunday = "SU"

        public var vEncoded: String { rawValue }
        
        public var weekday: Int {
            switch self {
            case .monday:
                return 2
            case .tuesday:
                return 3
            case .wednesday:
                return 4
            case .thursday:
                return 5
            case .friday:
                return 6
            case .saturday:
                return 7
            case .sunday:
                return 1
            }
        }
    }

    public struct Day: VEncodable {
        /// The week. May be negative.
        public let week: Int?
        /// The day of the week.
        public let dayOfWeek: DayOfWeek

        public var vEncoded: String { "\(week.map(String.init) ?? "")\(dayOfWeek.vEncoded)" }

        public init(week: Int? = nil, dayOfWeek: DayOfWeek) {
            self.week = week
            self.dayOfWeek = dayOfWeek

            assert(week.map { (1...53).contains(abs($0)) } ?? true, "Week-of-year \(week.map(String.init) ?? "?") is not between 1 and 53 or -53 and -1 (each inclusive)")
        }

        public static func every(_ dayOfWeek: DayOfWeek) -> Self {
            Self(dayOfWeek: dayOfWeek)
        }

        public static func first(_ dayOfWeek: DayOfWeek) -> Self {
            Self(week: 1, dayOfWeek: dayOfWeek)
        }

        public static func last(_ dayOfWeek: DayOfWeek) -> Self {
            Self(week: -1, dayOfWeek: dayOfWeek)
        }
        
        public static func from(_ value: String) -> Self? {
            let index = value.index(value.startIndex, offsetBy: value.count - 2)
           
            let dayOfWeekStr = String(value[index...])
            let weekStr = String(value[..<index])
            
            guard let dayOfWeek = DayOfWeek(rawValue: dayOfWeekStr) else {
                return nil
            }
            
            return .init(week: Int(weekStr), dayOfWeek: dayOfWeek)
        }
    }

    public init(
        frequency: Frequency,
        interval: Int? = nil,
        until: ICalDateTime? = nil,
        count: Int? = nil,
        bySecond: [Int]? = nil,
        byMinute: [Int]? = nil,
        byHour: [Int]? = nil,
        byDay: [Day]? = nil,
        byDayOfMonth: [Int]? = nil,
        byDayOfYear: [Int]? = nil,
        byWeekOfYear: [Int]? = nil,
        byMonth: [Int]? = nil,
        bySetPos: [Int]? = nil,
        startOfWorkweek: DayOfWeek? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.until = until
        self.count = count
        self.bySecond = bySecond
        self.byMinute = byMinute
        self.byHour = byHour
        self.byDay = byDay
        self.byDayOfMonth = byDayOfMonth
        self.byDayOfYear = byDayOfYear
        self.byWeekOfYear = byWeekOfYear
        self.byMonth = byMonth
        self.bySetPos = bySetPos
        self.startOfWorkweek = startOfWorkweek
    }
}
