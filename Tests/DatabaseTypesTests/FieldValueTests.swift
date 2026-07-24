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
                coefficient: 7,
                scale: 2
            ).decimalValue?.coefficient == 7
        )
        #expect(
            FieldValue.decimal(
                coefficient: 7,
                scale: 2
            ).decimalValue?.scale == 2
        )
    }

    @Test("Recursive values preserve structural identity")
    func recursiveIdentity() throws {
        let identity = try EntityIdentity(
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
}
