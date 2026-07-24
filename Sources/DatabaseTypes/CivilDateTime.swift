/// A Gregorian calendar date and time without a time zone or UTC offset.
///
/// This is the SQL `TIMESTAMP WITHOUT TIME ZONE` value domain. It does not
/// identify an absolute point in time until an upper layer supplies time-zone
/// and calendar resolution policy.
public struct CivilDateTime: Sendable, Hashable, Comparable {
    public let date: CivilDate
    public let time: CivilTime

    public init(date: CivilDate, time: CivilTime) {
        self.date = date
        self.time = time
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        return lhs.time < rhs.time
    }
}
