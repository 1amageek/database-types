import DatabaseTypes
import DatabaseTypesFoundation
#if canImport(FoundationEssentials)
import FoundationEssentials
private typealias FoundationUUID = FoundationEssentials.UUID
#else
import Foundation
private typealias FoundationUUID = Foundation.UUID
#endif
import Testing

@Suite("Foundation value conversion")
struct FoundationValueConversionTests {
    @Test("Date converts to canonical timestamp across the Unix epoch")
    func dateAndTimestampRoundTrip() throws {
        let date = Date(timeIntervalSince1970: -0.25)
        let timestamp = try Timestamp(date)

        #expect(timestamp.secondsSinceUnixEpoch == -1)
        #expect(timestamp.nanoseconds == 750_000_000)
        #expect(Date(timestamp).timeIntervalSince1970 == -0.25)
        #expect(throws: TimestampConversionError.nonFiniteDate) {
            _ = try Timestamp(
                Date(timeIntervalSince1970: .infinity)
            )
        }
    }

    @Test("Date conversion rounds its representable value to nanoseconds")
    func dateRounding() throws {
        let date = Date(timeIntervalSince1970: 0.000_000_1)
        let representedInterval = date.timeIntervalSince1970
        let expectedNanoseconds = UInt32(
            (representedInterval * 1_000_000_000)
                .rounded(.toNearestOrEven)
        )
        let timestamp = try Timestamp(date)

        #expect(timestamp.secondsSinceUnixEpoch == 0)
        #expect(timestamp.nanoseconds == expectedNanoseconds)
    }

    @Test("Civil date conversion requires explicit calendar and time zone")
    func civilDateUsesExplicitContext() throws {
        let instant = Date(timeIntervalSince1970: 0)
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let losAngeles = try #require(
            TimeZone(identifier: "America/Los_Angeles")
        )
        let calendar = Calendar(identifier: .iso8601)

        #expect(
            try CivilDate(
                containing: instant,
                calendar: calendar,
                timeZone: utc
            ) == CivilDate(year: 1970, month: 1, day: 1)
        )
        #expect(
            try CivilDate(
                containing: instant,
                calendar: calendar,
                timeZone: losAngeles
            ) == CivilDate(year: 1969, month: 12, day: 31)
        )
        #expect(throws: CivilDateConversionError.unsupportedCalendar) {
            _ = try CivilDate(
                containing: instant,
                calendar: Calendar(identifier: .buddhist),
                timeZone: utc
            )
        }
    }

    @Test("Date components convert only calendar-period amounts")
    func calendarPeriodConversion() throws {
        var components = DateComponents()
        components.year = 2
        components.month = 3
        components.day = 4

        let period = try CalendarPeriod(components)
        #expect(period == CalendarPeriod(months: 27, days: 4))
        let restored = try DateComponents(period)
        #expect(restored.month == 27)
        #expect(restored.day == 4)

        components.hour = 1
        #expect(
            throws: CalendarPeriodConversionError.unsupportedComponent
        ) {
            _ = try CalendarPeriod(components)
        }
    }

    @Test("Foundation data is retained without copying")
    func dataAndByteStringOwnership() throws {
        let data = Data(repeating: 0x5A, count: 4_096)
        let dataAddress = try #require(
            data.withUnsafeBytes { bytes in
                bytes.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        let bytes = ByteString(retaining: data)
        let byteStringAddress = try #require(
            bytes.withUnsafeBytes { buffer in
                buffer.baseAddress.map(UInt.init(bitPattern:))
            }
        )

        #expect(byteStringAddress == dataAddress)
        #expect(Data(copying: bytes) == data)
    }

    @Test("Foundation and canonical UUID values preserve all bits")
    func uuidRoundTrip() throws {
        let source = try #require(
            FoundationUUID(
                uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF"
            )
        )
        let canonical = DatabaseTypes.UUID(source)
        let restored = FoundationUUID(canonical)

        #expect(restored == source)
        #expect(canonical.description == source.uuidString.lowercased())
    }

    @Test("Foundation decimals convert only when exactly representable")
    func decimalRoundTrip() throws {
        let source = try #require(
            Decimal(
                string: "-12345.6789",
                locale: Locale(identifier: "en_US_POSIX")
            )
        )
        let canonical = try ExactDecimal(source)

        #expect(
            canonical
                == ExactDecimal(
                    coefficient: -123_456_789,
                    scale: 4
                )
        )
        #expect(try Decimal(canonical) == source)
        #expect(throws: ExactDecimalConversionError.nonFiniteValue) {
            _ = try ExactDecimal(Decimal.nan)
        }
        let wide = try #require(
            Decimal(
                string: "123456789012345678901234567890",
                locale: Locale(identifier: "en_US_POSIX")
            )
        )
        #expect(try Decimal(ExactDecimal(wide)) == wide)
        #expect(throws: ExactDecimalConversionError.coefficientOutOfRange) {
            _ = try ExactDecimal(Decimal.greatestFiniteMagnitude)
        }
        #expect(throws: ExactDecimalConversionError.valueOutOfRange) {
            _ = try Decimal(
                ExactDecimal(
                    coefficient: 1,
                    scale: 129
                )
            )
        }
    }
}
