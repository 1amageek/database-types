/// A canonical object of uniquely named field values.
///
/// Field order is not part of object identity. Construction validates exact
/// key identity and stores fields in UTF-8 order. The object can represent the
/// complete JSON object value model while also containing non-JSON
/// `FieldValue` primitives.
public struct FieldObject: Sendable {
    private let storage: [(key: String, value: FieldValue)]

    public init() {
        storage = []
    }

    /// Takes ownership of the supplied contiguous storage and canonicalizes it
    /// in place when uniquely referenced. Field payloads retain their existing
    /// copy-on-write storage.
    public init(
        _ fields: consuming [(key: String, value: FieldValue)]
    ) throws(FieldObjectError) {
        var fields = fields
        var requiresCanonicalization = false

        for index in fields.indices.dropFirst() {
            let previousKey = fields[index - 1].key
            let key = fields[index].key
            guard !StringIdentity.equal(previousKey, key) else {
                throw .duplicateKey(key)
            }
            if StringIdentity.less(key, previousKey) {
                requiresCanonicalization = true
                break
            }
        }

        if requiresCanonicalization {
            fields.sort {
                StringIdentity.less($0.key, $1.key)
            }
            for index in fields.indices.dropFirst() {
                let previousKey = fields[index - 1].key
                let key = fields[index].key
                guard !StringIdentity.equal(previousKey, key) else {
                    throw .duplicateKey(key)
                }
            }
        }

        storage = fields
    }

    public var count: Int {
        storage.count
    }

    public var isEmpty: Bool {
        storage.isEmpty
    }

    /// Returns the canonical contiguous fields without copying their payload
    /// storage. Mutating the returned array uses copy-on-write isolation.
    public var fields: [(key: String, value: FieldValue)] {
        storage
    }

    /// Performs exact key lookup without Unicode normalization.
    public subscript(key: String) -> FieldValue? {
        var lowerBound = storage.startIndex
        var upperBound = storage.endIndex

        while lowerBound < upperBound {
            let midpoint = lowerBound + (upperBound - lowerBound) / 2
            let candidate = storage[midpoint]
            if StringIdentity.equal(candidate.key, key) {
                return candidate.value
            }
            if StringIdentity.less(candidate.key, key) {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }
        return nil
    }
}

extension FieldObject: Hashable {
    // Comparison, hashing, and ordering route through the shared iterative
    // engine so a deeply nested object cannot overflow the stack and stays
    // identical to how the same object compares inside `FieldValue.object`.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        StructuralComparison.equal(.field(.object(lhs)), .field(.object(rhs)))
    }

    public func hash(into hasher: inout Hasher) {
        StructuralComparison.hash(.field(.object(self)), into: &hasher)
    }
}

extension FieldObject: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        StructuralComparison.compare(.field(.object(lhs)), .field(.object(rhs))) < 0
    }
}
