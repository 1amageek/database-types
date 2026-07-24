import DatabaseTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public extension Timestamp {
    /// Creates the canonical timestamp nearest to a Foundation date.
    ///
    /// Foundation dates use binary floating-point seconds. Conversion rounds
    /// the fractional part to the nearest nanosecond, resolving exact ties to
    /// the even nanosecond.
    init(_ date: Date) throws(TimestampConversionError) {
        let interval = date.timeIntervalSince1970
        guard interval.isFinite else {
            throw .nonFiniteDate
        }

        let integralInterval = interval.rounded(.down)
        guard var seconds = Int64(exactly: integralInterval) else {
            throw .valueOutOfRange
        }

        let fractionalInterval = interval - integralInterval
        var nanoseconds = Int64(
            (fractionalInterval * 1_000_000_000).rounded(.toNearestOrEven)
        )
        if nanoseconds == 1_000_000_000 {
            let incremented = seconds.addingReportingOverflow(1)
            guard !incremented.overflow else {
                throw .valueOutOfRange
            }
            seconds = incremented.partialValue
            nanoseconds = 0
        }

        guard let canonicalNanoseconds = UInt32(exactly: nanoseconds) else {
            throw .valueOutOfRange
        }

        do {
            try self.init(
                secondsSinceUnixEpoch: seconds,
                nanoseconds: canonicalNanoseconds
            )
        } catch {
            throw .valueOutOfRange
        }
    }
}

public extension Date {
    /// Creates a Foundation date for a canonical timestamp.
    ///
    /// Foundation dates use binary floating-point seconds. The result is the
    /// nearest value that `Date` can represent and may not preserve every
    /// nanosecond, especially far from the Unix epoch.
    init(_ timestamp: Timestamp) {
        self.init(
            timeIntervalSince1970:
                Double(timestamp.secondsSinceUnixEpoch)
                + Double(timestamp.nanoseconds) / 1_000_000_000
        )
    }
}
