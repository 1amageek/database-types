/// A node in the single iterative walk that backs equality, ordering, and
/// hashing for the recursive value types (`FieldValue`, `FieldObject`,
/// `ReferenceIdentifier`, `EntityReference`, `RDFTerm`).
///
/// These types reference one another: a `FieldValue` reaches a
/// `ReferenceIdentifier` and a nested `FieldObject` through `reference`, and an
/// `RDFTerm` through `rdfTerm`. Comparing them by delegating across type
/// boundaries would grow the call stack by one frame per crossing, so a value
/// that alternates types could still overflow even if each operator were
/// individually iterative. Mapping every recursive type onto this single node
/// lets one loop descend through all of them without any recursive call,
/// bounding call-stack use to O(1) regardless of the value's structural depth.
enum StructuralNode {
    case field(FieldValue)
    case identifier(ReferenceIdentifier)
    case term(RDFTerm)
}

/// The iterative engine shared by every recursive value type's `==`, `<`, and
/// `hash(into:)`. A single decomposition (`shallow` for ordering, `combine` for
/// hashing) is the sole source of truth, so the three operations cannot drift
/// out of agreement.
enum StructuralComparison {

    // MARK: - Ordering

    /// Returns a negative, zero, or positive value when `lhs` orders before,
    /// equal to, or after `rhs`.
    ///
    /// The walk is a left-to-right depth-first traversal: the first leaf that
    /// differs decides the result. A container is decomposed into its ordered
    /// child pairs followed by a length `tiebreak` marker, so a length
    /// difference only decides the order once every shared child has compared
    /// equal — reproducing lexicographic ordering without recursion.
    static func compare(_ lhs: StructuralNode, _ rhs: StructuralNode) -> Int {
        var stack: [Work] = [.pair(lhs, rhs)]
        while let work = stack.popLast() {
            switch work {
            case .tiebreak(let value):
                if value != 0 {
                    return value
                }
            case .pair(let left, let right):
                let outcome = shallow(left, right)
                if outcome.result != 0 {
                    return outcome.result
                }
                guard let children = outcome.children else {
                    continue
                }
                // Push the length tiebreak below the children so it is only
                // reached after every shared child has compared equal.
                if outcome.tiebreak != 0 {
                    stack.append(.tiebreak(outcome.tiebreak))
                }
                var index = children.count
                while index > 0 {
                    index -= 1
                    stack.append(.pair(children[index].0, children[index].1))
                }
            }
        }
        return 0
    }

    /// Structural equality, derived from `compare` so that `a == b` holds
    /// exactly when neither orders before the other. Both operations short
    /// circuit on the first differing leaf, so this performs the same work an
    /// independent equality walk would.
    static func equal(_ lhs: StructuralNode, _ rhs: StructuralNode) -> Bool {
        compare(lhs, rhs) == 0
    }

    // MARK: - Hashing

    /// Feeds a pre-order traversal of the value into `hasher`. Equal values
    /// visit an identical node sequence and feed identical bytes, so
    /// `equal(a, b)` implies matching hashes.
    static func hash(_ root: StructuralNode, into hasher: inout Hasher) {
        var stack: [StructuralNode] = [root]
        while let node = stack.popLast() {
            guard let children = combine(node, into: &hasher) else {
                continue
            }
            var index = children.count
            while index > 0 {
                index -= 1
                stack.append(children[index])
            }
        }
    }

    // MARK: - Work item

    private enum Work {
        case pair(StructuralNode, StructuralNode)
        case tiebreak(Int)
    }

    // MARK: - Shallow ordering

    /// The result of comparing one node without descending into its children.
    ///
    /// - `result`: a nonzero decision made at this node (rank or leaf
    ///   difference), or zero when the node is a container whose children must
    ///   be compared.
    /// - `children`: ordered child pairs to descend into, or `nil` for a leaf.
    /// - `tiebreak`: the length ordering applied after all shared children
    ///   compare equal; zero for leaves and fixed-arity containers.
    private struct Shallow {
        var result: Int
        var children: [(StructuralNode, StructuralNode)]?
        var tiebreak: Int

        static let equalLeaf = Shallow(result: 0, children: nil, tiebreak: 0)

        static func decided(_ result: Int) -> Shallow {
            Shallow(result: result, children: nil, tiebreak: 0)
        }

        static func container(
            _ children: [(StructuralNode, StructuralNode)],
            tiebreak: Int = 0
        ) -> Shallow {
            Shallow(result: 0, children: children, tiebreak: tiebreak)
        }
    }

    private static func shallow(
        _ left: StructuralNode,
        _ right: StructuralNode
    ) -> Shallow {
        switch (left, right) {
        case (.field(let left), .field(let right)):
            return shallowField(left, right)
        case (.identifier(let left), .identifier(let right)):
            return shallowIdentifier(left, right)
        case (.term(let left), .term(let right)):
            return shallowTerm(left, right)
        default:
            preconditionFailure("Structural walk paired incompatible node kinds")
        }
    }

    private static func shallowField(
        _ left: FieldValue,
        _ right: FieldValue
    ) -> Shallow {
        let leftRank = fieldRank(left)
        let rightRank = fieldRank(right)
        guard leftRank == rightRank else {
            return .decided(leftRank < rightRank ? -1 : 1)
        }

        switch (left, right) {
        case (.null, .null):
            return .equalLeaf
        case (.bool(let left), .bool(let right)):
            return .decided(ordering(equal: left == right, less: !left && right))
        case (.int8(let left), .int8(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.int16(let left), .int16(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.int32(let left), .int32(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.int64(let left), .int64(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint8(let left), .uint8(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint16(let left), .uint16(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint32(let left), .uint32(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint64(let left), .uint64(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.float32(let left), .float32(let right)):
            return .decided(orderingFloat(left, right))
        case (.float64(let left), .float64(let right)):
            return .decided(orderingFloat(left, right))
        case (.decimal(let left), .decimal(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.string(let left), .string(let right)):
            return .decided(
                ordering(
                    equal: StringIdentity.equal(left, right),
                    less: StringIdentity.less(left, right)
                )
            )
        case (.bytes(let left), .bytes(let right)):
            return .decided(
                ordering(
                    equal: left == right,
                    less: left.lexicographicallyPrecedes(right)
                )
            )
        case (.date(let left), .date(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.time(let left), .time(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.dateTime(let left), .dateTime(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.timestamp(let left), .timestamp(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.timeSpan(let left), .timeSpan(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.calendarPeriod(let left), .calendarPeriod(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.geographicPoint(let left), .geographicPoint(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.geographicPosition(let left), .geographicPosition(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.vector(let left), .vector(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uuid(let left), .uuid(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.array(let left), .array(let right)):
            return arrayShallow(left, right)
        case (.object(let left), .object(let right)):
            return objectShallow(left, right)
        case (.reference(let left), .reference(let right)):
            return referenceShallow(left, right)
        case (.rdfTerm(let left), .rdfTerm(let right)):
            return .container([(.term(left), .term(right))])
        default:
            preconditionFailure("Field ranks matched but cases did not")
        }
    }

    private static func arrayShallow(
        _ left: [FieldValue],
        _ right: [FieldValue]
    ) -> Shallow {
        let shared = min(left.count, right.count)
        var children: [(StructuralNode, StructuralNode)] = []
        children.reserveCapacity(shared)
        for index in 0..<shared {
            children.append((.field(left[index]), .field(right[index])))
        }
        return .container(
            children,
            tiebreak: lengthOrdering(left.count, right.count)
        )
    }

    private static func objectShallow(
        _ left: FieldObject,
        _ right: FieldObject
    ) -> Shallow {
        let leftFields = left.fields
        let rightFields = right.fields
        let shared = min(leftFields.count, rightFields.count)
        // Each field contributes a key comparison followed by a value
        // comparison, reproducing `FieldObject`'s key-then-value ordering.
        var children: [(StructuralNode, StructuralNode)] = []
        children.reserveCapacity(shared * 2)
        for index in 0..<shared {
            children.append(
                (
                    .field(.string(leftFields[index].key)),
                    .field(.string(rightFields[index].key))
                )
            )
            children.append(
                (
                    .field(leftFields[index].value),
                    .field(rightFields[index].value)
                )
            )
        }
        return .container(
            children,
            tiebreak: lengthOrdering(leftFields.count, rightFields.count)
        )
    }

    private static func referenceShallow(
        _ left: EntityReference,
        _ right: EntityReference
    ) -> Shallow {
        // Fixed arity: entity, then identifier, then partitions.
        let children: [(StructuralNode, StructuralNode)] = [
            (.field(.string(left.entity)), .field(.string(right.entity))),
            (.identifier(left.id), .identifier(right.id)),
            (.field(.object(left.partitions)), .field(.object(right.partitions))),
        ]
        return .container(children)
    }

    private static func shallowIdentifier(
        _ left: ReferenceIdentifier,
        _ right: ReferenceIdentifier
    ) -> Shallow {
        let leftRank = identifierRank(left)
        let rightRank = identifierRank(right)
        guard leftRank == rightRank else {
            return .decided(leftRank < rightRank ? -1 : 1)
        }

        switch (left, right) {
        case (.bool(let left), .bool(let right)):
            return .decided(ordering(equal: left == right, less: !left && right))
        case (.int8(let left), .int8(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.int16(let left), .int16(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.int32(let left), .int32(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.int64(let left), .int64(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint8(let left), .uint8(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint16(let left), .uint16(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint32(let left), .uint32(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uint64(let left), .uint64(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.string(let left), .string(let right)):
            return .decided(
                ordering(
                    equal: StringIdentity.equal(left, right),
                    less: StringIdentity.less(left, right)
                )
            )
        case (.bytes(let left), .bytes(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.uuid(let left), .uuid(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.composite(let left), .composite(let right)):
            let shared = min(left.count, right.count)
            var children: [(StructuralNode, StructuralNode)] = []
            children.reserveCapacity(shared)
            for index in 0..<shared {
                children.append((.identifier(left[index]), .identifier(right[index])))
            }
            return .container(
                children,
                tiebreak: lengthOrdering(left.count, right.count)
            )
        default:
            preconditionFailure("Identifier ranks matched but cases did not")
        }
    }

    private static func shallowTerm(
        _ left: RDFTerm,
        _ right: RDFTerm
    ) -> Shallow {
        let leftRank = termRank(left)
        let rightRank = termRank(right)
        guard leftRank == rightRank else {
            return .decided(leftRank < rightRank ? -1 : 1)
        }

        switch (left, right) {
        case (.blankNode(let left), .blankNode(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.iri(let left), .iri(let right)):
            return .decided(ordering(equal: left == right, less: left < right))
        case (.literal(let left), .literal(let right)):
            return .decided(orderingLiteral(left, right))
        case (
            .tripleTerm(let leftSubject, let leftPredicate, let leftObject),
            .tripleTerm(let rightSubject, let rightPredicate, let rightObject)
        ):
            // Fixed arity: subject, then predicate, then object. Subject and
            // predicate are mapped through `term`, which preserves their
            // ordering and equality against the recursive definition.
            let children: [(StructuralNode, StructuralNode)] = [
                (.term(leftSubject.term), .term(rightSubject.term)),
                (.term(leftPredicate.term), .term(rightPredicate.term)),
                (.term(leftObject), .term(rightObject)),
            ]
            return .container(children)
        default:
            preconditionFailure("Term ranks matched but cases did not")
        }
    }

    private static func orderingLiteral(
        _ left: RDFLiteral,
        _ right: RDFLiteral
    ) -> Int {
        if left.annotation != right.annotation {
            return left.annotation < right.annotation ? -1 : 1
        }
        return ordering(
            equal: StringIdentity.equal(left.lexicalForm, right.lexicalForm),
            less: StringIdentity.less(left.lexicalForm, right.lexicalForm)
        )
    }

    private static func ordering(equal: Bool, less: Bool) -> Int {
        if equal {
            return 0
        }
        return less ? -1 : 1
    }

    private static func orderingFloat(_ left: Float, _ right: Float) -> Int {
        if left.bitPattern == right.bitPattern {
            return 0
        }
        return left.isTotallyOrdered(belowOrEqualTo: right) ? -1 : 1
    }

    private static func orderingFloat(_ left: Double, _ right: Double) -> Int {
        if left.bitPattern == right.bitPattern {
            return 0
        }
        return left.isTotallyOrdered(belowOrEqualTo: right) ? -1 : 1
    }

    private static func lengthOrdering(_ left: Int, _ right: Int) -> Int {
        if left == right {
            return 0
        }
        return left < right ? -1 : 1
    }

    // MARK: - Shallow hashing

    private static func combine(
        _ node: StructuralNode,
        into hasher: inout Hasher
    ) -> [StructuralNode]? {
        switch node {
        case .field(let value):
            return combineField(value, into: &hasher)
        case .identifier(let value):
            return combineIdentifier(value, into: &hasher)
        case .term(let value):
            return combineTerm(value, into: &hasher)
        }
    }

    private static func combineField(
        _ value: FieldValue,
        into hasher: inout Hasher
    ) -> [StructuralNode]? {
        switch value {
        case .null:
            hasher.combine(0 as UInt8)
        case .bool(let value):
            hasher.combine(1 as UInt8)
            hasher.combine(value)
        case .int8(let value):
            hasher.combine(2 as UInt8)
            hasher.combine(value)
        case .int16(let value):
            hasher.combine(3 as UInt8)
            hasher.combine(value)
        case .int32(let value):
            hasher.combine(4 as UInt8)
            hasher.combine(value)
        case .int64(let value):
            hasher.combine(5 as UInt8)
            hasher.combine(value)
        case .uint8(let value):
            hasher.combine(6 as UInt8)
            hasher.combine(value)
        case .uint16(let value):
            hasher.combine(7 as UInt8)
            hasher.combine(value)
        case .uint32(let value):
            hasher.combine(8 as UInt8)
            hasher.combine(value)
        case .uint64(let value):
            hasher.combine(9 as UInt8)
            hasher.combine(value)
        case .float32(let value):
            hasher.combine(10 as UInt8)
            hasher.combine(value.bitPattern)
        case .float64(let value):
            hasher.combine(11 as UInt8)
            hasher.combine(value.bitPattern)
        case .decimal(let value):
            hasher.combine(12 as UInt8)
            hasher.combine(value)
        case .string(let value):
            hasher.combine(13 as UInt8)
            StringIdentity.hash(value, into: &hasher)
        case .bytes(let value):
            hasher.combine(14 as UInt8)
            hasher.combine(value)
        case .date(let value):
            hasher.combine(15 as UInt8)
            hasher.combine(value)
        case .time(let value):
            hasher.combine(16 as UInt8)
            hasher.combine(value)
        case .dateTime(let value):
            hasher.combine(17 as UInt8)
            hasher.combine(value)
        case .timestamp(let value):
            hasher.combine(18 as UInt8)
            hasher.combine(value)
        case .timeSpan(let value):
            hasher.combine(19 as UInt8)
            hasher.combine(value)
        case .calendarPeriod(let value):
            hasher.combine(20 as UInt8)
            hasher.combine(value)
        case .geographicPoint(let value):
            hasher.combine(21 as UInt8)
            hasher.combine(value)
        case .geographicPosition(let value):
            hasher.combine(22 as UInt8)
            hasher.combine(value)
        case .vector(let value):
            hasher.combine(23 as UInt8)
            hasher.combine(value)
        case .uuid(let value):
            hasher.combine(24 as UInt8)
            hasher.combine(value)
        case .array(let values):
            hasher.combine(25 as UInt8)
            hasher.combine(values.count)
            return values.map { .field($0) }
        case .object(let object):
            hasher.combine(26 as UInt8)
            let fields = object.fields
            hasher.combine(fields.count)
            var children: [StructuralNode] = []
            children.reserveCapacity(fields.count * 2)
            for field in fields {
                children.append(.field(.string(field.key)))
                children.append(.field(field.value))
            }
            return children
        case .reference(let reference):
            hasher.combine(27 as UInt8)
            return [
                .field(.string(reference.entity)),
                .identifier(reference.id),
                .field(.object(reference.partitions)),
            ]
        case .rdfTerm(let term):
            hasher.combine(28 as UInt8)
            return [.term(term)]
        }
        return nil
    }

    private static func combineIdentifier(
        _ value: ReferenceIdentifier,
        into hasher: inout Hasher
    ) -> [StructuralNode]? {
        switch value {
        case .bool(let value):
            hasher.combine(0 as UInt8)
            hasher.combine(value)
        case .int8(let value):
            hasher.combine(1 as UInt8)
            hasher.combine(value)
        case .int16(let value):
            hasher.combine(2 as UInt8)
            hasher.combine(value)
        case .int32(let value):
            hasher.combine(3 as UInt8)
            hasher.combine(value)
        case .int64(let value):
            hasher.combine(4 as UInt8)
            hasher.combine(value)
        case .uint8(let value):
            hasher.combine(5 as UInt8)
            hasher.combine(value)
        case .uint16(let value):
            hasher.combine(6 as UInt8)
            hasher.combine(value)
        case .uint32(let value):
            hasher.combine(7 as UInt8)
            hasher.combine(value)
        case .uint64(let value):
            hasher.combine(8 as UInt8)
            hasher.combine(value)
        case .string(let value):
            hasher.combine(9 as UInt8)
            StringIdentity.hash(value, into: &hasher)
        case .bytes(let value):
            hasher.combine(10 as UInt8)
            hasher.combine(value)
        case .uuid(let value):
            hasher.combine(11 as UInt8)
            hasher.combine(value)
        case .composite(let values):
            hasher.combine(12 as UInt8)
            hasher.combine(values.count)
            return values.map { .identifier($0) }
        }
        return nil
    }

    private static func combineTerm(
        _ term: RDFTerm,
        into hasher: inout Hasher
    ) -> [StructuralNode]? {
        switch term {
        case .blankNode(let value):
            hasher.combine(0 as UInt8)
            hasher.combine(value)
        case .iri(let value):
            hasher.combine(1 as UInt8)
            hasher.combine(value)
        case .literal(let value):
            hasher.combine(2 as UInt8)
            StringIdentity.hash(value.lexicalForm, into: &hasher)
            hasher.combine(value.annotation)
        case .tripleTerm(let subject, let predicate, let object):
            hasher.combine(3 as UInt8)
            return [.term(subject.term), .term(predicate.term), .term(object)]
        }
        return nil
    }

    // MARK: - Case ranks

    private static func fieldRank(_ value: FieldValue) -> UInt8 {
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

    private static func identifierRank(_ value: ReferenceIdentifier) -> UInt8 {
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

    private static func termRank(_ term: RDFTerm) -> UInt8 {
        switch term {
        case .blankNode: return 0
        case .iri: return 1
        case .literal: return 2
        case .tripleTerm: return 3
        }
    }
}
