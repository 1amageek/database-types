import DatabaseTypes
import Testing

@Suite("FieldValue")
struct FieldValueTests {
    @Test("Every fixed-width numeric representation has distinct identity")
    func fixedWidthNumericIdentity() {
        let values: [FieldValue] = [
            .int8(1),
            .int16(1),
            .int32(1),
            .int64(1),
            .uint8(1),
            .uint16(1),
            .uint32(1),
            .uint64(1),
            .float32(1),
            .float64(1),
        ]

        #expect(Set(values).count == values.count)
    }

    @Test("Floating-point identity preserves the exact bit pattern")
    func floatingPointIdentity() {
        let negativeZero32 = FieldValue.float32(-0.0)
        let positiveZero32 = FieldValue.float32(0.0)
        let negativeZero64 = FieldValue.float64(-0.0)
        let positiveZero64 = FieldValue.float64(0.0)

        #expect(negativeZero32 != positiveZero32)
        #expect(negativeZero64 != positiveZero64)
        #expect((negativeZero32 < positiveZero32) !=
            (positiveZero32 < negativeZero32))
        #expect((negativeZero64 < positiveZero64) !=
            (positiveZero64 < negativeZero64))
    }

    @Test("String identity preserves the source Unicode scalar sequence")
    func stringIdentity() {
        let composed = FieldValue.string("é")
        let decomposed = FieldValue.string("e\u{301}")

        #expect(composed != decomposed)
        #expect(Set([composed, decomposed]).count == 2)
        #expect((composed < decomposed) != (decomposed < composed))
    }

    @Test("Accessors never coerce numeric representations")
    func exactAccessors() {
        #expect(FieldValue.int8(7).int8Value == 7)
        #expect(FieldValue.int8(7).int64Value == nil)
        #expect(FieldValue.uint32(7).uint32Value == 7)
        #expect(FieldValue.uint32(7).uint64Value == nil)
        #expect(FieldValue.float32(7).float32Value == 7)
        #expect(FieldValue.float32(7).float64Value == nil)
        #expect(
            FieldValue.decimal(
                ExactDecimal(coefficient: 7, scale: 2)
            ).decimalValue?.coefficient == 7
        )
        #expect(
            FieldValue.decimal(
                ExactDecimal(coefficient: 7, scale: 2)
            ).decimalValue?.scale == 2
        )
    }

    @Test("Recursive values preserve structural identity")
    func recursiveIdentity() throws {
        let identity = try EntityReference(
            entity: "Event",
            id: .composite([
                .uint16(7),
                .uuid(try #require(UUID(
                    canonicalString: "00000000-0000-0000-0000-000000000001"
                ))),
            ]),
            partitions: [
                try ObjectField(
                    number: 1,
                    name: "calendar",
                    value: .string("primary")
                ),
            ]
        )
        let value = FieldValue.object([
            try ObjectField(
                number: 1,
                name: "reference",
                value: .reference(identity)
            ),
        ])

        #expect(value == value)
        #expect(Set([value, value]).count == 1)
    }

    @Test("Temporal primitive cases participate in the total order")
    func temporalPrimitiveOrdering() throws {
        let values: [FieldValue] = [
            .date(try CivilDate(year: 2026, month: 7, day: 24)),
            .time(try CivilTime(hour: 12, minute: 0, second: 0)),
            .dateTime(CivilDateTime(
                date: try CivilDate(year: 2026, month: 7, day: 24),
                time: try CivilTime(hour: 12, minute: 0, second: 0)
            )),
            .timestamp(try Timestamp(secondsSinceUnixEpoch: 0)),
            .timeSpan(try TimeSpan(seconds: 1)),
            .calendarPeriod(CalendarPeriod(months: 1)),
            .geographicPoint(
                try GeographicPoint(latitude: 0, longitude: 0)
            ),
            .vector(try Vector(float32: [1, 2])),
        ]

        #expect(values.sorted() == values)
        #expect(Set(values).count == values.count)
    }

    @Test("Every field case participates in one strict total order")
    func totalOrderLaws() throws {
        let objectField = try ObjectField(
            number: 1,
            name: "value",
            value: .string("nested")
        )
        let reference = try EntityReference(
            entity: "Event",
            id: .uint64(1)
        )
        let values: [FieldValue] = [
            .null,
            .bool(false),
            .int8(-1),
            .int16(-1),
            .int32(-1),
            .int64(-1),
            .uint8(1),
            .uint16(1),
            .uint32(1),
            .uint64(1),
            .float32(-0.0),
            .float64(-0.0),
            .decimal(ExactDecimal(coefficient: 1, scale: 1)),
            .string("value"),
            .bytes([1]),
            .date(try CivilDate(year: 2026, month: 7, day: 24)),
            .time(try CivilTime(hour: 1, minute: 2, second: 3)),
            .dateTime(CivilDateTime(
                date: try CivilDate(year: 2026, month: 7, day: 24),
                time: try CivilTime(hour: 1, minute: 2, second: 3)
            )),
            .timestamp(try Timestamp(secondsSinceUnixEpoch: 1)),
            .timeSpan(try TimeSpan(seconds: 1)),
            .calendarPeriod(CalendarPeriod(months: 1)),
            .geographicPoint(
                try GeographicPoint(latitude: 1, longitude: 2)
            ),
            .vector(try Vector(float32: [1])),
            .uuid(try #require(UUID(
                canonicalString: "00000000-0000-0000-0000-000000000001"
            ))),
            .array([.null]),
            .object([objectField]),
            .reference(reference),
            .rdfTerm(.iri(try RDFIRI("urn:database-types:value"))),
        ]

        #expect(values.sorted() == values)
        for leftIndex in values.indices {
            for rightIndex in values.indices where leftIndex != rightIndex {
                let left = values[leftIndex]
                let right = values[rightIndex]
                #expect((left < right) != (right < left))
            }
        }
    }
}
