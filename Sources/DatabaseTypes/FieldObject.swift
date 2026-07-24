/// A canonical object composed of uniquely identified fields.
///
/// Field order is not part of object identity. Construction validates unique
/// field numbers and exact field-name identity, then stores fields in ascending
/// number order. The canonical contiguous storage supports deterministic
/// equality, hashing, comparison, wire iteration, and storage encoding.
public struct FieldObject:
    Sendable,
    Hashable,
    Comparable,
    RandomAccessCollection {
    public typealias Element = ObjectField
    public typealias Index = Int

    private let fields: [ObjectField]

    public init(
        _ sourceFields: [ObjectField]
    ) throws(FieldObjectError) {
        var numbers: Set<UInt32> = []
        numbers.reserveCapacity(sourceFields.count)
        var names: Set<ObjectFieldNameIdentity> = []
        names.reserveCapacity(sourceFields.count)

        var isCanonicalOrder = true
        var previousNumber: UInt32?
        for field in sourceFields {
            guard numbers.insert(field.number).inserted else {
                throw .duplicateFieldNumber(field.number)
            }
            guard names.insert(ObjectFieldNameIdentity(field.name)).inserted
            else {
                throw .duplicateFieldName(field.name)
            }
            if let previousNumber, previousNumber >= field.number {
                isCanonicalOrder = false
            }
            previousNumber = field.number
        }

        if isCanonicalOrder {
            self.fields = sourceFields
        } else {
            self.fields = sourceFields.sorted {
                $0.number < $1.number
            }
        }
    }

    public var startIndex: Int { fields.startIndex }
    public var endIndex: Int { fields.endIndex }

    public subscript(position: Int) -> ObjectField {
        fields[position]
    }

    /// Materializes an independently owned array for array-only APIs.
    public func copyFields() -> [ObjectField] {
        Array(fields)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let sharedCount = Swift.min(lhs.count, rhs.count)
        for offset in 0..<sharedCount {
            let left = lhs.fields[offset]
            let right = rhs.fields[offset]
            if left != right {
                return left < right
            }
        }
        return lhs.count < rhs.count
    }
}

private struct ObjectFieldNameIdentity: Hashable {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        StringIdentity.equal(lhs.value, rhs.value)
    }

    func hash(into hasher: inout Hasher) {
        StringIdentity.hash(value, into: &hasher)
    }
}
