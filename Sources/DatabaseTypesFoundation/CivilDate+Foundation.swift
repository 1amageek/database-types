import DatabaseTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public extension CivilDate {
    /// Derives a proleptic Gregorian civil date using explicit calendar
    /// and time-zone context.
    ///
    /// Only Gregorian and ISO 8601 calendars are accepted because `CivilDate`
    /// represents the SQL `DATE` Gregorian calendar rather than an arbitrary
    /// calendrical system.
    init(
        containing date: Date,
        calendar sourceCalendar: Calendar,
        timeZone: TimeZone
    ) throws(CivilDateConversionError) {
        guard sourceCalendar.identifier == .gregorian
                || sourceCalendar.identifier == .iso8601 else {
            throw .unsupportedCalendar
        }

        var calendar = sourceCalendar
        calendar.timeZone = timeZone
        let components = calendar.dateComponents(
            [.era, .year, .month, .day],
            from: date
        )
        guard let era = components.era,
              let componentYear = components.year,
              let month = components.month,
              let day = components.day else {
            throw .missingDateComponents
        }

        let astronomicalYear: Int
        switch era {
        case 0:
            astronomicalYear = 1 - componentYear
        case 1:
            astronomicalYear = componentYear
        default:
            throw .missingDateComponents
        }

        guard let year = Int32(exactly: astronomicalYear) else {
            throw .yearOutOfRange(astronomicalYear)
        }
        guard let canonicalMonth = UInt8(exactly: month),
              let canonicalDay = UInt8(exactly: day) else {
            throw .missingDateComponents
        }

        do {
            try self.init(
                year: year,
                month: canonicalMonth,
                day: canonicalDay
            )
        } catch {
            throw .invalidDate(error)
        }
    }
}
