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

    @Test("CivilTime admits only one nanosecond-resolved time of day")
    func civilTimeValidation() throws {
        let finalNanosecond = try CivilTime(
            hour: 23,
            minute: 59,
            second: 59,
            nanoseconds: 999_999_999
        )
        #expect(
            try CivilTime(hour: 0, minute: 0, second: 0)
                < finalNanosecond
        )
        #expect(throws: CivilTimeError.invalidHour(24)) {
            _ = try CivilTime(hour: 24, minute: 0, second: 0)
        }
        #expect(throws: CivilTimeError.invalidSecond(60)) {
            _ = try CivilTime(hour: 0, minute: 0, second: 60)
        }
    }

    @Test("CivilDateTime orders local calendar components")
    func civilDateTimeOrdering() throws {
        let earlier = CivilDateTime(
            date: try CivilDate(year: 2026, month: 7, day: 24),
            time: try CivilTime(hour: 9, minute: 0, second: 0)
        )
        let later = CivilDateTime(
            date: earlier.date,
            time: try CivilTime(hour: 10, minute: 0, second: 0)
        )
        #expect(earlier < later)
    }

    @Test("TimeSpan uses one floor-based fractional representation")
    func timeSpanValidation() throws {
        let negativeHalfSecond = try TimeSpan(
            seconds: -1,
            nanoseconds: 500_000_000
        )
        #expect(
            negativeHalfSecond < (try TimeSpan(seconds: 0))
        )
        #expect(
            throws: TimeSpanError.invalidNanoseconds(1_000_000_000)
        ) {
            _ = try TimeSpan(
                seconds: 0,
                nanoseconds: 1_000_000_000
            )
        }
    }

    @Test("Swift Duration conversion rounds once at nanosecond precision")
    func durationConversion() throws {
        let lowerTie = Duration(
            secondsComponent: 0,
            attosecondsComponent: 2_500_000_000
        )
        let upperTie = Duration(
            secondsComponent: 0,
            attosecondsComponent: 3_500_000_000
        )
        let negativeHalfSecond = Duration.milliseconds(-500)

        #expect(
            try TimeSpan(rounding: lowerTie)
                == TimeSpan(seconds: 0, nanoseconds: 2)
        )
        #expect(
            try TimeSpan(rounding: upperTie)
                == TimeSpan(seconds: 0, nanoseconds: 4)
        )
        let negative = try TimeSpan(rounding: negativeHalfSecond)
        #expect(negative.seconds == -1)
        #expect(negative.nanoseconds == 500_000_000)
        #expect(Duration(negative) == negativeHalfSecond)
    }

    @Test("CalendarPeriod keeps months distinct from days")
    func calendarPeriodValidation() throws {
        let period = try CalendarPeriod(years: 2, months: 3, days: 4)
        #expect(period.months == 27)
        #expect(period.days == 4)
        #expect(period < CalendarPeriod(months: 28))
        #expect(throws: CalendarPeriodError.monthOverflow) {
            _ = try CalendarPeriod(years: Int64.max)
        }
    }

    @Test("GeographicPoint validates WGS 84 coordinate bounds")
    func geographicPointValidation() throws {
        let origin = try GeographicPoint(latitude: -0.0, longitude: 0.0)
        let north = try GeographicPoint(latitude: 1, longitude: 0)
        #expect(origin.latitude.bitPattern == 0.0.bitPattern)
        #expect(origin.longitude.bitPattern == 0.0.bitPattern)
        #expect(origin < north)
        #expect(
            throws: GeographicPointError.latitudeOutOfRange(91)
        ) {
            _ = try GeographicPoint(latitude: 91, longitude: 0)
        }
        #expect(throws: GeographicPointError.nonFiniteLongitude) {
            _ = try GeographicPoint(latitude: 0, longitude: .infinity)
        }
    }

    @Test("GeographicPosition preserves finite WGS 84 ellipsoidal height")
    func geographicPositionValidation() throws {
        let surface = try GeographicPosition(
            latitude: 35.681_236,
            longitude: 139.767_125,
            ellipsoidalHeightInMeters: -0.0
        )
        let elevated = try GeographicPosition(
            point: surface.point,
            ellipsoidalHeightInMeters: 10
        )

        #expect(surface.ellipsoidalHeightInMeters.bitPattern == 0.0.bitPattern)
        #expect(surface < elevated)
        #expect(
            throws: GeographicPositionError.nonFiniteEllipsoidalHeight
        ) {
            _ = try GeographicPosition(
                point: surface.point,
                ellipsoidalHeightInMeters: .infinity
            )
        }
        #expect(
            throws: GeographicPositionError.invalidPoint(
                .latitudeOutOfRange(91)
            )
        ) {
            _ = try GeographicPosition(
                latitude: 91,
                longitude: 0,
                ellipsoidalHeightInMeters: 0
            )
        }
    }

    @Test("Vector preserves width and slices retained storage")
    func vectorOwnershipAndIdentity() throws {
        let elements: [Float] = [1, 2, 3, 4]
        let sourceAddress = try #require(
            elements.withUnsafeBufferPointer { buffer in
                buffer.baseAddress.map(UInt.init(bitPattern:))
            }
        )
        let vector = try Vector(float32: elements)
        let vectorAddress = try #require(
            vector.withFloat32Elements { buffer in
                buffer.baseAddress.map(UInt.init(bitPattern:))
            }
        )
        #expect(vectorAddress == sourceAddress)

        let slice = vector.subvector(in: 1..<3)
        let sliceAddress = try #require(
            slice.withFloat32Elements { buffer in
                buffer.baseAddress.map(UInt.init(bitPattern:))
            }
        )
        #expect(
            sliceAddress == sourceAddress + UInt(MemoryLayout<Float>.stride)
        )
        #expect(slice.count == 2)
        let wideVector = try Vector(float64: [1, 2, 3, 4])
        #expect(vector != wideVector)
        #expect(throws: VectorError.nonFiniteFloat32(index: 1)) {
            _ = try Vector(float32: [0, .nan])
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

    @Test("Composite reference identifiers reject empty components")
    func identifierValidation() throws {
        let value = ReferenceIdentifier.composite([
            .int8(1),
            .composite([
                .uint64(2),
                .string("three"),
            ]),
        ])

        try value.validate()
        #expect(throws: ReferenceIdentifierValidationError.emptyComposite) {
            try ReferenceIdentifier.composite([]).validate()
        }
    }

    @Test("Identifier widths have distinct identity and total ordering")
    func identifierIdentity() {
        let values: [ReferenceIdentifier] = [
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
        #expect(throws: EntityReferenceError.emptyEntity) {
            _ = try EntityReference(entity: "", id: .int64(1))
        }
        #expect(
            throws: EntityReferenceError.invalidIdentifier(.emptyComposite)
        ) {
            _ = try EntityReference(
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
