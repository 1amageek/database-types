/// An exact, context-free elapsed time with nanosecond resolution.
///
/// The value is `seconds + nanoseconds / 1_000_000_000`. `seconds` uses floor
/// representation, so negative fractional values remain canonical: negative
/// half a second is `seconds: -1, nanoseconds: 500_000_000`.
public struct TimeSpan: Sendable, Hashable, Comparable {
    public let seconds: Int64
    public let nanoseconds: UInt32

    public init(
        seconds: Int64,
        nanoseconds: UInt32 = 0
    ) throws(TimeSpanError) {
        guard nanoseconds < 1_000_000_000 else {
            throw .invalidNanoseconds(nanoseconds)
        }
        self.seconds = seconds
        self.nanoseconds = nanoseconds
    }

    /// Rounds a Swift duration to the nearest nanosecond.
    ///
    /// Exact half-nanosecond ties are resolved to the even nanosecond.
    public init(
        rounding duration: Duration
    ) throws(TimeSpanConversionError) {
        let components = duration.components
        let attosecondsPerNanosecond: Int64 = 1_000_000_000
        var roundedNanoseconds = components.attoseconds
            / attosecondsPerNanosecond
        let remainder = components.attoseconds % attosecondsPerNanosecond
        let remainderMagnitude = remainder.magnitude
        let halfNanosecond = UInt64(attosecondsPerNanosecond / 2)

        if remainderMagnitude > halfNanosecond
            || (remainderMagnitude == halfNanosecond
                && !roundedNanoseconds.isMultiple(of: 2)) {
            roundedNanoseconds += remainder < 0 ? -1 : 1
        }

        var seconds = components.seconds
        if roundedNanoseconds == 1_000_000_000 {
            let adjusted = seconds.addingReportingOverflow(1)
            guard !adjusted.overflow else {
                throw .valueOutOfRange
            }
            seconds = adjusted.partialValue
            roundedNanoseconds = 0
        } else if roundedNanoseconds < 0 {
            let adjusted = seconds.subtractingReportingOverflow(1)
            guard !adjusted.overflow else {
                throw .valueOutOfRange
            }
            seconds = adjusted.partialValue
            roundedNanoseconds += 1_000_000_000
        }

        self.seconds = seconds
        self.nanoseconds = UInt32(roundedNanoseconds)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.seconds != rhs.seconds {
            return lhs.seconds < rhs.seconds
        }
        return lhs.nanoseconds < rhs.nanoseconds
    }
}

extension Duration {
    /// Creates an exact Swift duration from a nanosecond-resolved time span.
    public init(_ timeSpan: TimeSpan) {
        self.init(
            secondsComponent: timeSpan.seconds,
            attosecondsComponent: Int64(timeSpan.nanoseconds) * 1_000_000_000
        )
    }
}
