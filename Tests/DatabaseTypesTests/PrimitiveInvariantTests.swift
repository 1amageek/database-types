import DatabaseTypes
import Testing

@Suite("Primitive invariants")
struct PrimitiveInvariantTests {
    @Test("CivilDate admits only real proleptic Gregorian dates")
    func civilDateValidation() throws {
        #expect(
            try CivilDate(year: 2000, month: 2, day: 29)
                < CivilDate(year: 2000, month: 3, day: 1)
        )
        #expect(
            throws: CivilDateError.invalidDay(
                29,
                year: 1900,
                month: 2,
                maximum: 28
            )
        ) {
            _ = try CivilDate(year: 1900, month: 2, day: 29)
        }
        #expect(throws: CivilDateError.invalidMonth(0)) {
            _ = try CivilDate(year: 2026, month: 0, day: 1)
        }
    }

    @Test("Timestamp admits only canonical subsecond values")
    func timestampValidation() throws {
        let value = try Timestamp(
            secondsSinceUnixEpoch: -1,
            nanoseconds: 999_999_999
        )

        #expect(value.nanoseconds == 999_999_999)
        #expect(
            throws: TimestampError.invalidNanoseconds(1_000_000_000)
        ) {
            _ = try Timestamp(
                secondsSinceUnixEpoch: 0,
                nanoseconds: 1_000_000_000
            )
        }
    }

    @Test("UUID parses and formats one canonical 128-bit value")
    func uuidRoundTrip() throws {
        let spelling = "01234567-89ab-cdef-0123-456789abcdef"
        let value = try #require(UUID(canonicalString: spelling))

        #expect(value.description == spelling)
        #expect(value.count == 16)
        #expect(UUID(bytes: value) == value)
        #expect(UUID(canonicalString: "\(spelling)0") == nil)
    }

    @Test("Composite identifiers are validated iteratively and within limits")
    func identifierValidation() throws {
        let value = IdentifierValue.composite([
            .int8(1),
            .composite([
                .uint64(2),
                .string("three"),
            ]),
        ])

        try value.validate()
        #expect(throws: IdentifierValidationError.emptyComposite) {
            try IdentifierValue.composite([]).validate()
        }
        #expect(
            throws: IdentifierValidationError.compositeDepthExceeded(
                actual: 2,
                maximum: 1
            )
        ) {
            try value.validate(
                limits: IdentifierLimits(
                    maximumCompositeDepth: 1,
                    maximumComponentCount: 10
                )
            )
        }
    }

    @Test("Identifier widths have distinct identity and total ordering")
    func identifierIdentity() {
        let values: [IdentifierValue] = [
            .int8(1),
            .int16(1),
            .int32(1),
            .int64(1),
            .uint8(1),
            .uint16(1),
            .uint32(1),
            .uint64(1),
        ]

        #expect(Set(values).count == values.count)
        for leftIndex in values.indices {
            for rightIndex in values.indices where leftIndex != rightIndex {
                let left = values[leftIndex]
                let right = values[rightIndex]
                #expect((left < right) != (right < left))
            }
        }
    }

    @Test("Fields and entity identities reject invalid structure")
    func structuralValueValidation() throws {
        #expect(throws: ObjectFieldError.invalidNumber(0)) {
            _ = try ObjectField(
                number: 0,
                name: "invalid",
                value: .null
            )
        }
        #expect(throws: EntityIdentityError.emptyEntity) {
            _ = try EntityIdentity(entity: "", id: .int64(1))
        }
        #expect(
            throws: EntityIdentityError.invalidIdentifier(.emptyComposite)
        ) {
            _ = try EntityIdentity(
                entity: "Event",
                id: .composite([])
            )
        }
    }

    @Test("RDF atomic values reject invalid construction")
    func rdfValidation() throws {
        #expect(throws: RDFBlankNodeIdentifierError.empty) {
            _ = try RDFBlankNodeIdentifier("")
        }
        #expect(throws: RDFIRIError.self) {
            _ = try RDFIRI("relative")
        }

        let subject = RDFSubject.blankNode(
            try RDFBlankNodeIdentifier("event")
        )
        let predicate = try RDFPredicateIRI("urn:calendar:title")
        let object = RDFTerm.literal(RDFLiteral(
            lexicalForm: "Calendar",
            datatype: XSDDatatype.string.typedLiteralDatatype
        ))
        let term = RDFTerm.tripleTerm(
            subject: subject,
            predicate: predicate,
            object: object
        )

        #expect(term.description.contains("urn:calendar:title"))
    }
}
