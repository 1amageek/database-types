/// A proleptic Gregorian calendar date without a time or time zone.
///
/// This is the SQL `DATE` value domain. It is intentionally distinct from
/// `Timestamp`; converting between them requires an explicit calendar and time
/// zone in a platform adapter or upper semantic layer.
public struct CivilDate: Sendable, Hashable, Comparable {
    public let year: Int32
    public let month: UInt8
    public let day: UInt8

    public init(
        year: Int32,
        month: UInt8,
        day: UInt8
    ) throws(CivilDateError) {
        guard (1...12).contains(month) else {
            throw .invalidMonth(month)
        }
        let maximumDay = Self.daysInMonth(year: year, month: month)
        guard day >= 1, day <= maximumDay else {
            throw .invalidDay(
                day,
                year: year,
                month: month,
                maximum: maximumDay
            )
        }
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: CivilDate, rhs: CivilDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    private static func daysInMonth(
        year: Int32,
        month: UInt8
    ) -> UInt8 {
        switch month {
        case 2:
            let year = Int64(year)
            let isLeapYear = year.isMultiple(of: 4)
                && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
            return isLeapYear ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
}
