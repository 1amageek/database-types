/// A time of day without a date, time zone, or UTC offset.
///
/// `CivilTime` follows the SQL `TIME` value domain. Leap seconds are not
/// represented; valid values range from 00:00:00 through
/// 23:59:59.999999999.
public struct CivilTime: Sendable, Hashable, Comparable {
    public let hour: UInt8
    public let minute: UInt8
    public let second: UInt8
    public let nanoseconds: UInt32

    public init(
        hour: UInt8,
        minute: UInt8,
        second: UInt8,
        nanoseconds: UInt32 = 0
    ) throws(CivilTimeError) {
        guard hour < 24 else {
            throw .invalidHour(hour)
        }
        guard minute < 60 else {
            throw .invalidMinute(minute)
        }
        guard second < 60 else {
            throw .invalidSecond(second)
        }
        guard nanoseconds < 1_000_000_000 else {
            throw .invalidNanoseconds(nanoseconds)
        }

        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanoseconds = nanoseconds
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
        if lhs.minute != rhs.minute { return lhs.minute < rhs.minute }
        if lhs.second != rhs.second { return lhs.second < rhs.second }
        return lhs.nanoseconds < rhs.nanoseconds
    }
}
