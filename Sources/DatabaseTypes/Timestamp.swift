/// An absolute point on the Unix time line with nanosecond resolution.
///
/// The representation has no calendar or time zone. `nanoseconds` is always in
/// `0..<1_000_000_000`, including for points before the Unix epoch.
public struct Timestamp: Sendable, Hashable, Comparable {
    public let secondsSinceUnixEpoch: Int64
    public let nanoseconds: UInt32

    public init(
        secondsSinceUnixEpoch: Int64,
        nanoseconds: UInt32 = 0
    ) throws(TimestampError) {
        guard nanoseconds < 1_000_000_000 else {
            throw .invalidNanoseconds(nanoseconds)
        }
        self.secondsSinceUnixEpoch = secondsSinceUnixEpoch
        self.nanoseconds = nanoseconds
    }

    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        if lhs.secondsSinceUnixEpoch != rhs.secondsSinceUnixEpoch {
            return lhs.secondsSinceUnixEpoch < rhs.secondsSinceUnixEpoch
        }
        return lhs.nanoseconds < rhs.nanoseconds
    }
}
