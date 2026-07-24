import DatabaseTypes
import Testing

/// Validates that the iterative equality, ordering, and hashing engine behind
/// the recursive value types reproduces the intended total order, stays
/// self-consistent, and never overflows the stack — regardless of value depth.
///
/// The iterative engine is internal, so these tests reach it only through the
/// public `==`, `<`, and `hash` of `FieldValue`, `FieldObject`,
/// `ReferenceIdentifier`, `EntityReference`, and `RDFTerm`. An independent
/// recursive oracle, written against the public surface, is the reference the
/// engine is checked against on randomly generated deep trees.
@Suite("Structural comparison engine")
struct StructuralComparisonTests {

    // MARK: - Random engine-vs-oracle agreement

    @Test("Iterative ordering matches an independent recursive oracle")
    func iterativeOrderingMatchesOracle() throws {
        let pools = try ValuePools()
        for seed in 0..<400 {
            var generator = SplitMix64(seed: 0xA53F_0000 &+ UInt64(seed))
            let values = (0..<8).map { _ in
                pools.field(depth: 5, using: &generator)
            }
            for left in values {
                for right in values {
                    let oracle = oracleCompareField(left, right)
                    #expect((left == right) == (oracle == 0))
                    #expect((left < right) == (oracle < 0))
                    #expect((right < left) == (oracle > 0))
                }
            }
        }
    }

    // MARK: - Total-order algebra

    @Test("Ordering is a strict total order (trichotomy, antisymmetry, transitivity)")
    func orderingIsStrictTotalOrder() throws {
        let pools = try ValuePools()
        for seed in 0..<300 {
            var generator = SplitMix64(seed: 0x00C0_FFEE &+ UInt64(seed))
            let values = (0..<10).map { _ in
                pools.field(depth: 5, using: &generator)
            }

            for left in values {
                #expect(left == left)
                #expect(!(left < left))
                for right in values {
                    let less = left < right
                    let greater = right < left
                    let equal = left == right
                    // Exactly one of <, ==, > holds.
                    #expect([less, equal, greater].filter { $0 }.count == 1)
                    // Antisymmetry.
                    if less {
                        #expect(!greater)
                    }
                    // Equality agrees with hashing.
                    if equal {
                        #expect(left.hashValue == right.hashValue)
                    }
                }
            }

            for a in values {
                for b in values where a < b {
                    for c in values where b < c {
                        #expect(a < c)
                    }
                }
            }
        }
    }

    // MARK: - Hash consistency for independently built equal values

    @Test("Equal values built from independent storage hash and compare equal")
    func independentlyBuiltEqualValuesAgree() throws {
        let pools = try ValuePools()
        for seed in 0..<400 {
            let base = 0x1234_5670 &+ UInt64(seed)
            var left = SplitMix64(seed: base)
            var right = SplitMix64(seed: base)
            // Same seed, separate allocations: structurally equal, not shared.
            let a = pools.field(depth: 5, using: &left)
            let b = pools.field(depth: 5, using: &right)
            #expect(a == b)
            #expect(!(a < b))
            #expect(!(b < a))
            #expect(a.hashValue == b.hashValue)
        }
    }

    // MARK: - Intended-order spot checks (anchored, not oracle-derived)

    @Test("Case rank orders every kind before the next")
    func caseRankOrdersKinds() throws {
        let ascending: [FieldValue] = [
            .null,
            .bool(false),
            .int8(0),
            .int16(0),
            .int32(0),
            .int64(0),
            .uint8(0),
            .uint16(0),
            .uint32(0),
            .uint64(0),
            .float32(0),
            .float64(0),
            .decimal(ExactDecimal(coefficient: 0, scale: 0)),
            .string(""),
            .bytes(ByteString([])),
            .uuid(UUID(high: 0, low: 0)),
            .array([]),
            .object(FieldObject()),
        ]
        for lower in ascending.indices {
            for upper in ascending.indices where lower < upper {
                #expect(ascending[lower] < ascending[upper])
                #expect(!(ascending[upper] < ascending[lower]))
                #expect(ascending[lower] != ascending[upper])
            }
        }
    }

    @Test("Arrays order lexicographically with length as the final tiebreak")
    func arraysOrderLexicographically() {
        #expect(FieldValue.array([.int64(1)]) < .array([.int64(2)]))
        #expect(FieldValue.array([.int64(1)]) < .array([.int64(1), .int64(0)]))
        #expect(
            FieldValue.array([.int64(1), .int64(0)])
                < .array([.int64(1), .int64(9)])
        )
        // A first-element difference dominates a later-element difference.
        #expect(
            FieldValue.array([.int64(0), .int64(9)])
                < .array([.int64(1), .int64(0)])
        )
    }

    @Test("Objects order by key then value with field count as the final tiebreak")
    func objectsOrderByKeyThenValue() throws {
        let single = try FieldObject([(key: "a", value: .int64(1))])
        let sameKeyLargerValue = try FieldObject([(key: "a", value: .int64(2))])
        let laterKey = try FieldObject([(key: "b", value: .int64(0))])
        let twoFields = try FieldObject([
            (key: "a", value: .int64(1)),
            (key: "b", value: .int64(0)),
        ])

        // Equal shared key, value decides.
        #expect(FieldValue.object(single) < .object(sameKeyLargerValue))
        // Key difference dominates the value difference.
        #expect(FieldValue.object(sameKeyLargerValue) < .object(laterKey))
        // Shared prefix equal, fewer fields orders first.
        #expect(FieldValue.object(single) < .object(twoFields))
    }

    @Test("Composite identifiers order lexicographically with length as tiebreak")
    func compositeIdentifiersOrder() {
        let single = ReferenceIdentifier.composite([.int64(1)])
        let largerElement = ReferenceIdentifier.composite([.int64(2)])
        let longer = ReferenceIdentifier.composite([.int64(1), .int64(0)])

        #expect(single < largerElement)
        #expect(single < longer)
        // A scalar identifier is distinct from a one-element composite.
        #expect(ReferenceIdentifier.int64(1) != single)
        #expect(ReferenceIdentifier.int64(1) < single)
    }

    @Test("Triple terms order by subject then predicate then object")
    func tripleTermsOrderByPosition() throws {
        let subjectA = RDFSubject.iri(try RDFIRI("urn:s:a"))
        let subjectB = RDFSubject.iri(try RDFIRI("urn:s:b"))
        let predicateA = try RDFPredicateIRI("urn:p:a")
        let predicateB = try RDFPredicateIRI("urn:p:b")
        let objectA = RDFTerm.iri(try RDFIRI("urn:o:a"))
        let objectB = RDFTerm.iri(try RDFIRI("urn:o:b"))

        let base = RDFTerm.tripleTerm(
            subject: subjectA,
            predicate: predicateA,
            object: objectA
        )
        let laterObject = RDFTerm.tripleTerm(
            subject: subjectA,
            predicate: predicateA,
            object: objectB
        )
        let laterPredicate = RDFTerm.tripleTerm(
            subject: subjectA,
            predicate: predicateB,
            object: objectA
        )
        let laterSubject = RDFTerm.tripleTerm(
            subject: subjectB,
            predicate: predicateA,
            object: objectA
        )

        #expect(base < laterObject)
        // A predicate difference dominates the object difference.
        #expect(laterObject < laterPredicate)
        // A subject difference dominates the predicate difference.
        #expect(laterPredicate < laterSubject)
    }

    // MARK: - Deep structures do not overflow the stack

    @Test("Deeply nested arrays compare and hash without overflowing")
    func deeplyNestedArraysDoNotOverflow() {
        let depth = 100_000
        var equalLeft = FieldValue.int64(0)
        var equalRight = FieldValue.int64(0)
        var deeperLeaf = FieldValue.int64(1)
        for _ in 0..<depth {
            equalLeft = .array([equalLeft])
            equalRight = .array([equalRight])
            deeperLeaf = .array([deeperLeaf])
        }

        #expect(equalLeft == equalRight)
        #expect(!(equalLeft < equalRight))
        #expect(equalLeft.hashValue == equalRight.hashValue)
        // The only difference is the deepest leaf: 0 < 1.
        #expect(equalLeft < deeperLeaf)
        #expect(!(deeperLeaf < equalLeft))
        #expect(equalLeft != deeperLeaf)

        // Swift releases a nested indirect enum recursively, so dismantle these
        // values one level at a time before they leave scope. This teardown
        // cost is a property of the value type, not of the comparison engine.
        dismantle(&equalLeft)
        dismantle(&equalRight)
        dismantle(&deeperLeaf)
    }

    @Test("Deeply nested composite identifiers compare and hash without overflowing")
    func deeplyNestedCompositesDoNotOverflow() {
        let depth = 100_000
        var identifier = ReferenceIdentifier.int64(0)
        var other = ReferenceIdentifier.int64(1)
        for _ in 0..<depth {
            identifier = .composite([identifier])
            other = .composite([other])
        }

        #expect(identifier == identifier)
        #expect(!(identifier < identifier))
        #expect(identifier.hashValue == identifier.hashValue)
        #expect(identifier < other)

        dismantle(&identifier)
        dismantle(&other)
    }

    @Test("Deeply nested triple terms compare and hash without overflowing")
    func deeplyNestedTripleTermsDoNotOverflow() throws {
        let subject = RDFSubject.iri(try RDFIRI("urn:s:deep"))
        let predicate = try RDFPredicateIRI("urn:p:deep")
        var term = RDFTerm.iri(try RDFIRI("urn:o:a"))
        var other = RDFTerm.iri(try RDFIRI("urn:o:b"))
        for _ in 0..<50_000 {
            term = .tripleTerm(subject: subject, predicate: predicate, object: term)
            other = .tripleTerm(subject: subject, predicate: predicate, object: other)
        }

        #expect(term == term)
        #expect(!(term < term))
        #expect(term.hashValue == term.hashValue)
        // Deepest object differs: urn:o:a < urn:o:b.
        #expect(term < other)

        dismantle(&term)
        dismantle(&other)
    }

    @Test("A deep chain that alternates value types does not overflow")
    func deepAlternatingTypesDoNotOverflow() throws {
        // Alternating array / object / reference forces the walk to cross type
        // boundaries at every level. A delegating comparator would add a call
        // frame per crossing; the single-loop engine must stay flat.
        var equalA = FieldValue.int64(0)
        var equalB = FieldValue.int64(0)
        var deeperLeaf = FieldValue.int64(1)
        for index in 0..<30_000 {
            switch index % 3 {
            case 0:
                equalA = .array([equalA])
                equalB = .array([equalB])
                deeperLeaf = .array([deeperLeaf])
            case 1:
                equalA = .object(try FieldObject([(key: "k", value: equalA)]))
                equalB = .object(try FieldObject([(key: "k", value: equalB)]))
                deeperLeaf = .object(try FieldObject([(key: "k", value: deeperLeaf)]))
            default:
                equalA = .reference(
                    try EntityReference(
                        entity: "e",
                        id: .int64(1),
                        partitions: try FieldObject([(key: "p", value: equalA)])
                    )
                )
                equalB = .reference(
                    try EntityReference(
                        entity: "e",
                        id: .int64(1),
                        partitions: try FieldObject([(key: "p", value: equalB)])
                    )
                )
                deeperLeaf = .reference(
                    try EntityReference(
                        entity: "e",
                        id: .int64(1),
                        partitions: try FieldObject([(key: "p", value: deeperLeaf)])
                    )
                )
            }
        }

        #expect(equalA == equalB)
        #expect(equalA.hashValue == equalB.hashValue)
        #expect(!(equalA < equalB))
        #expect(equalA < deeperLeaf)
        #expect(!(deeperLeaf < equalA))
        #expect(equalA != deeperLeaf)

        dismantle(&equalA)
        dismantle(&equalB)
        dismantle(&deeperLeaf)
    }
}

// MARK: - Iterative teardown for deeply nested values

/// Unwraps a single-child container one level at a time so ARC releases each
/// box shallowly. Reassigning to the child keeps it retained while the parent
/// is freed, so no recursive release occurs.
private func dismantle(_ value: inout FieldValue) {
    while true {
        switch value {
        case .array(let elements):
            guard elements.count == 1 else { return }
            value = elements[0]
        case .object(let object):
            let fields = object.fields
            guard fields.count == 1 else { return }
            value = fields[0].value
        case .reference(let reference):
            let fields = reference.partitions.fields
            guard fields.count == 1 else { return }
            value = fields[0].value
        default:
            return
        }
    }
}

private func dismantle(_ identifier: inout ReferenceIdentifier) {
    while case .composite(let components) = identifier, components.count == 1 {
        identifier = components[0]
    }
}

private func dismantle(_ term: inout RDFTerm) {
    while case .tripleTerm(_, _, let object) = term {
        term = object
    }
}

// MARK: - Independent recursive oracle (public surface only)

private func oracleCompareField(_ left: FieldValue, _ right: FieldValue) -> Int {
    let leftRank = fieldRank(left)
    let rightRank = fieldRank(right)
    if leftRank != rightRank {
        return leftRank < rightRank ? -1 : 1
    }
    switch (left, right) {
    case (.null, .null):
        return 0
    case (.bool(let a), .bool(let b)):
        return a == b ? 0 : (!a && b ? -1 : 1)
    case (.int8(let a), .int8(let b)):
        return triadic(a == b, a < b)
    case (.int16(let a), .int16(let b)):
        return triadic(a == b, a < b)
    case (.int32(let a), .int32(let b)):
        return triadic(a == b, a < b)
    case (.int64(let a), .int64(let b)):
        return triadic(a == b, a < b)
    case (.uint8(let a), .uint8(let b)):
        return triadic(a == b, a < b)
    case (.uint16(let a), .uint16(let b)):
        return triadic(a == b, a < b)
    case (.uint32(let a), .uint32(let b)):
        return triadic(a == b, a < b)
    case (.uint64(let a), .uint64(let b)):
        return triadic(a == b, a < b)
    case (.float32(let a), .float32(let b)):
        if a.bitPattern == b.bitPattern { return 0 }
        return a.isTotallyOrdered(belowOrEqualTo: b) ? -1 : 1
    case (.float64(let a), .float64(let b)):
        if a.bitPattern == b.bitPattern { return 0 }
        return a.isTotallyOrdered(belowOrEqualTo: b) ? -1 : 1
    case (.decimal(let a), .decimal(let b)):
        return triadic(a == b, a < b)
    case (.string(let a), .string(let b)):
        return oracleStringCompare(a, b)
    case (.bytes(let a), .bytes(let b)):
        return triadic(a == b, a.lexicographicallyPrecedes(b))
    case (.date(let a), .date(let b)):
        return triadic(a == b, a < b)
    case (.time(let a), .time(let b)):
        return triadic(a == b, a < b)
    case (.dateTime(let a), .dateTime(let b)):
        return triadic(a == b, a < b)
    case (.timestamp(let a), .timestamp(let b)):
        return triadic(a == b, a < b)
    case (.timeSpan(let a), .timeSpan(let b)):
        return triadic(a == b, a < b)
    case (.calendarPeriod(let a), .calendarPeriod(let b)):
        return triadic(a == b, a < b)
    case (.geographicPoint(let a), .geographicPoint(let b)):
        return triadic(a == b, a < b)
    case (.geographicPosition(let a), .geographicPosition(let b)):
        return triadic(a == b, a < b)
    case (.vector(let a), .vector(let b)):
        return triadic(a == b, a < b)
    case (.uuid(let a), .uuid(let b)):
        return triadic(a == b, a < b)
    case (.array(let a), .array(let b)):
        let shared = min(a.count, b.count)
        for index in 0..<shared {
            let element = oracleCompareField(a[index], b[index])
            if element != 0 { return element }
        }
        return triadic(a.count == b.count, a.count < b.count)
    case (.object(let a), .object(let b)):
        return oracleCompareObject(a, b)
    case (.reference(let a), .reference(let b)):
        return oracleCompareReference(a, b)
    case (.rdfTerm(let a), .rdfTerm(let b)):
        return oracleCompareTerm(a, b)
    default:
        return 0
    }
}

private func oracleCompareObject(_ left: FieldObject, _ right: FieldObject) -> Int {
    let leftFields = left.fields
    let rightFields = right.fields
    let shared = min(leftFields.count, rightFields.count)
    for index in 0..<shared {
        let key = oracleStringCompare(leftFields[index].key, rightFields[index].key)
        if key != 0 { return key }
        let value = oracleCompareField(leftFields[index].value, rightFields[index].value)
        if value != 0 { return value }
    }
    return triadic(leftFields.count == rightFields.count, leftFields.count < rightFields.count)
}

private func oracleCompareReference(_ left: EntityReference, _ right: EntityReference) -> Int {
    let entity = oracleStringCompare(left.entity, right.entity)
    if entity != 0 { return entity }
    let identifier = oracleCompareIdentifier(left.id, right.id)
    if identifier != 0 { return identifier }
    return oracleCompareObject(left.partitions, right.partitions)
}

private func oracleCompareIdentifier(
    _ left: ReferenceIdentifier,
    _ right: ReferenceIdentifier
) -> Int {
    let leftRank = identifierRank(left)
    let rightRank = identifierRank(right)
    if leftRank != rightRank {
        return leftRank < rightRank ? -1 : 1
    }
    switch (left, right) {
    case (.bool(let a), .bool(let b)):
        return a == b ? 0 : (!a && b ? -1 : 1)
    case (.int8(let a), .int8(let b)):
        return triadic(a == b, a < b)
    case (.int16(let a), .int16(let b)):
        return triadic(a == b, a < b)
    case (.int32(let a), .int32(let b)):
        return triadic(a == b, a < b)
    case (.int64(let a), .int64(let b)):
        return triadic(a == b, a < b)
    case (.uint8(let a), .uint8(let b)):
        return triadic(a == b, a < b)
    case (.uint16(let a), .uint16(let b)):
        return triadic(a == b, a < b)
    case (.uint32(let a), .uint32(let b)):
        return triadic(a == b, a < b)
    case (.uint64(let a), .uint64(let b)):
        return triadic(a == b, a < b)
    case (.string(let a), .string(let b)):
        return oracleStringCompare(a, b)
    case (.bytes(let a), .bytes(let b)):
        return triadic(a == b, a < b)
    case (.uuid(let a), .uuid(let b)):
        return triadic(a == b, a < b)
    case (.composite(let a), .composite(let b)):
        let shared = min(a.count, b.count)
        for index in 0..<shared {
            let element = oracleCompareIdentifier(a[index], b[index])
            if element != 0 { return element }
        }
        return triadic(a.count == b.count, a.count < b.count)
    default:
        return 0
    }
}

private func oracleCompareTerm(_ left: RDFTerm, _ right: RDFTerm) -> Int {
    let leftRank = termRank(left)
    let rightRank = termRank(right)
    if leftRank != rightRank {
        return leftRank < rightRank ? -1 : 1
    }
    switch (left, right) {
    case (.blankNode(let a), .blankNode(let b)):
        return triadic(a == b, a < b)
    case (.iri(let a), .iri(let b)):
        return triadic(a == b, a < b)
    case (.literal(let a), .literal(let b)):
        if a.annotation != b.annotation {
            return a.annotation < b.annotation ? -1 : 1
        }
        return oracleStringCompare(a.lexicalForm, b.lexicalForm)
    case (
        .tripleTerm(let leftSubject, let leftPredicate, let leftObject),
        .tripleTerm(let rightSubject, let rightPredicate, let rightObject)
    ):
        if leftSubject != rightSubject {
            return leftSubject < rightSubject ? -1 : 1
        }
        if leftPredicate != rightPredicate {
            return leftPredicate < rightPredicate ? -1 : 1
        }
        return oracleCompareTerm(leftObject, rightObject)
    default:
        return 0
    }
}

private func oracleStringCompare(_ left: String, _ right: String) -> Int {
    var leftBytes = left.utf8.makeIterator()
    var rightBytes = right.utf8.makeIterator()
    while true {
        switch (leftBytes.next(), rightBytes.next()) {
        case (.none, .none):
            return 0
        case (.none, .some):
            return -1
        case (.some, .none):
            return 1
        case (.some(let leftByte), .some(let rightByte)):
            if leftByte != rightByte {
                return leftByte < rightByte ? -1 : 1
            }
        }
    }
}

private func triadic(_ equal: Bool, _ less: Bool) -> Int {
    if equal { return 0 }
    return less ? -1 : 1
}

private func fieldRank(_ value: FieldValue) -> UInt8 {
    switch value {
    case .null: return 0
    case .bool: return 1
    case .int8: return 2
    case .int16: return 3
    case .int32: return 4
    case .int64: return 5
    case .uint8: return 6
    case .uint16: return 7
    case .uint32: return 8
    case .uint64: return 9
    case .float32: return 10
    case .float64: return 11
    case .decimal: return 12
    case .string: return 13
    case .bytes: return 14
    case .date: return 15
    case .time: return 16
    case .dateTime: return 17
    case .timestamp: return 18
    case .timeSpan: return 19
    case .calendarPeriod: return 20
    case .geographicPoint: return 21
    case .geographicPosition: return 22
    case .vector: return 23
    case .uuid: return 24
    case .array: return 25
    case .object: return 26
    case .reference: return 27
    case .rdfTerm: return 28
    }
}

private func identifierRank(_ value: ReferenceIdentifier) -> UInt8 {
    switch value {
    case .bool: return 0
    case .int8: return 1
    case .int16: return 2
    case .int32: return 3
    case .int64: return 4
    case .uint8: return 5
    case .uint16: return 6
    case .uint32: return 7
    case .uint64: return 8
    case .string: return 9
    case .bytes: return 10
    case .uuid: return 11
    case .composite: return 12
    }
}

private func termRank(_ term: RDFTerm) -> UInt8 {
    switch term {
    case .blankNode: return 0
    case .iri: return 1
    case .literal: return 2
    case .tripleTerm: return 3
    }
}

// MARK: - Deterministic random value generation

/// A seeded SplitMix64 generator so failures reproduce from their seed.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Pre-validated building blocks so generation itself never throws.
private struct ValuePools {
    let leaves: [FieldValue]
    let keys: [String]
    let entities: [String]
    let scalarIdentifiers: [ReferenceIdentifier]
    let termLeaves: [RDFTerm]
    let subjects: [RDFSubject]
    let predicates: [RDFPredicateIRI]

    init() throws {
        let iris = [
            try RDFIRI("urn:x:a"),
            try RDFIRI("urn:x:b"),
            try RDFIRI("https://example.com/1"),
        ]
        let blankNodes = [
            try RDFBlankNodeIdentifier("b0"),
            try RDFBlankNodeIdentifier("b1"),
        ]
        let literals = [
            RDFLiteral(lexicalForm: "", datatype: .xsdString),
            RDFLiteral(lexicalForm: "a", datatype: .xsdString),
            RDFLiteral(
                lexicalForm: "a",
                datatype: XSDDatatype.boolean.typedLiteralDatatype
            ),
            RDFLiteral(lexicalForm: "b", language: try RDFLanguageTag("en")),
        ]
        termLeaves =
            iris.map { .iri($0) }
            + blankNodes.map { .blankNode($0) }
            + literals.map { .literal($0) }
        subjects =
            iris.map { .iri($0) } + blankNodes.map { .blankNode($0) }
        predicates = [
            try RDFPredicateIRI("urn:p:1"),
            try RDFPredicateIRI("urn:p:2"),
        ]
        keys = ["", "a", "b", "ab", "key"]
        entities = ["A", "B", "entity"]
        scalarIdentifiers = [
            .bool(false),
            .bool(true),
            .int64(-1),
            .int64(0),
            .int64(1),
            .string(""),
            .string("a"),
            .string("b"),
            .uuid(UUID(high: 0, low: 1)),
            .bytes(ByteString([1, 2])),
        ]
        leaves = [
            .null,
            .bool(false),
            .bool(true),
            .int8(-1),
            .int8(0),
            .int64(.min),
            .int64(.max),
            .uint32(0),
            .uint32(7),
            .float64(0),
            .float64(-0.0),
            .float64(.nan),
            .float64(.infinity),
            .float64(-.infinity),
            .float64(1.5),
            .float32(2.5),
            .decimal(ExactDecimal(coefficient: 0, scale: 0)),
            .decimal(ExactDecimal(coefficient: 5, scale: 1)),
            .decimal(ExactDecimal(coefficient: -3, scale: 0)),
            .string(""),
            .string("a"),
            .string("b"),
            .string("ab"),
            .bytes(ByteString([])),
            .bytes(ByteString([1, 2])),
            .uuid(UUID(high: 0, low: 0)),
            .uuid(UUID(high: 1, low: 0)),
        ]
    }

    func field(depth: Int, using generator: inout SplitMix64) -> FieldValue {
        if depth <= 0 || Int.random(in: 0..<3, using: &generator) == 0 {
            return leaves.randomElement(using: &generator)!
        }
        switch Int.random(in: 0..<5, using: &generator) {
        case 0:
            let count = Int.random(in: 0..<4, using: &generator)
            var elements: [FieldValue] = []
            elements.reserveCapacity(count)
            for _ in 0..<count {
                elements.append(field(depth: depth - 1, using: &generator))
            }
            return .array(elements)
        case 1:
            return .object(object(depth: depth, keyLimit: 4, using: &generator))
        case 2:
            let identifier = identifier(depth: depth - 1, using: &generator)
            let partitions = object(depth: depth, keyLimit: 3, using: &generator)
            let entity = entities.randomElement(using: &generator)!
            // Non-empty entity and validated identifier: never throws.
            guard
                let reference = try? EntityReference(
                    entity: entity,
                    id: identifier,
                    partitions: partitions
                )
            else {
                return leaves.randomElement(using: &generator)!
            }
            return .reference(reference)
        default:
            return .rdfTerm(term(depth: depth - 1, using: &generator))
        }
    }

    private func object(
        depth: Int,
        keyLimit: Int,
        using generator: inout SplitMix64
    ) -> FieldObject {
        let count = Int.random(in: 0..<keyLimit, using: &generator)
        var used = Set<String>()
        var pairs: [(key: String, value: FieldValue)] = []
        for _ in 0..<count {
            let key = keys.randomElement(using: &generator)!
            guard used.insert(key).inserted else {
                continue
            }
            pairs.append((key: key, value: field(depth: depth - 1, using: &generator)))
        }
        // Unique keys guarantee a successful construction.
        guard let object = try? FieldObject(pairs) else {
            return FieldObject()
        }
        return object
    }

    private func identifier(
        depth: Int,
        using generator: inout SplitMix64
    ) -> ReferenceIdentifier {
        if depth <= 0 || Int.random(in: 0..<2, using: &generator) == 0 {
            return scalarIdentifiers.randomElement(using: &generator)!
        }
        // At least one component keeps the composite valid.
        let count = Int.random(in: 1..<4, using: &generator)
        var components: [ReferenceIdentifier] = []
        components.reserveCapacity(count)
        for _ in 0..<count {
            components.append(identifier(depth: depth - 1, using: &generator))
        }
        return .composite(components)
    }

    private func term(depth: Int, using generator: inout SplitMix64) -> RDFTerm {
        if depth <= 0 || Int.random(in: 0..<2, using: &generator) == 0 {
            return termLeaves.randomElement(using: &generator)!
        }
        return .tripleTerm(
            subject: subjects.randomElement(using: &generator)!,
            predicate: predicates.randomElement(using: &generator)!,
            object: term(depth: depth - 1, using: &generator)
        )
    }
}
