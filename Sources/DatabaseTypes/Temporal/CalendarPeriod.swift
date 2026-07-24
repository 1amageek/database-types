/// A context-dependent calendar amount expressed as total months and days.
///
/// Months are not converted to days because their duration depends on the
/// calendar position where the period is applied. Sub-day elapsed time belongs
/// to `TimeSpan`.
public struct CalendarPeriod: Sendable, Hashable, Comparable {
    public let months: Int64
    public let days: Int64

    public init(months: Int64 = 0, days: Int64 = 0) {
        self.months = months
        self.days = days
    }

    public init(
        years: Int64,
        months: Int64 = 0,
        days: Int64 = 0
    ) throws(CalendarPeriodError) {
        let multiplied = years.multipliedReportingOverflow(by: 12)
        guard !multiplied.overflow else {
            throw .monthOverflow
        }
        let totalMonths = multiplied.partialValue.addingReportingOverflow(
            months
        )
        guard !totalMonths.overflow else {
            throw .monthOverflow
        }
        self.init(months: totalMonths.partialValue, days: days)
    }

    /// Provides a deterministic structural order, not an elapsed-time order.
    ///
    /// Calendar periods cannot be ordered by duration without a calendar
    /// position. The total order compares months first and then days.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.months != rhs.months {
            return lhs.months < rhs.months
        }
        return lhs.days < rhs.days
    }
}
