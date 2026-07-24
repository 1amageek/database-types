import DatabaseTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public extension CalendarPeriod {
    /// Creates a period from the year, month, and day amount components.
    ///
    /// Date-position and sub-day components are rejected rather than ignored.
    init(
        _ components: DateComponents
    ) throws(CalendarPeriodConversionError) {
        guard components.calendar == nil,
              components.timeZone == nil,
              components.era == nil,
              components.hour == nil,
              components.minute == nil,
              components.second == nil,
              components.nanosecond == nil,
              components.weekday == nil,
              components.weekdayOrdinal == nil,
              components.quarter == nil,
              components.weekOfMonth == nil,
              components.weekOfYear == nil,
              components.yearForWeekOfYear == nil,
              components.isLeapMonth == nil else {
            throw .unsupportedComponent
        }

        guard let years = Int64(exactly: components.year ?? 0),
              let months = Int64(exactly: components.month ?? 0),
              let days = Int64(exactly: components.day ?? 0) else {
            throw .valueOutOfRange
        }

        do {
            try self.init(years: years, months: months, days: days)
        } catch {
            throw .monthOverflow
        }
    }
}

public extension DateComponents {
    /// Creates year/month/day components without calendar or time-zone policy.
    init(_ period: CalendarPeriod) throws(CalendarPeriodConversionError) {
        guard let months = Int(exactly: period.months),
              let days = Int(exactly: period.days) else {
            throw .valueOutOfRange
        }
        self.init()
        self.month = months
        self.day = days
    }
}
