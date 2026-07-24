/// A canonical object composed of uniquely identified fields.
///
/// Field order is not part of object identity. Construction validates unique
/// field numbers and exact field-name identity, then stores fields in ascending
/// number order. The canonical contiguous storage supports deterministic
/// equality, hashing, comparison, wire iteration, and storage encoding.
public struct ObjectValue:
    Sendable,
    Hashable,
    Comparable,
    RandomAccessCollection {
    public typealias Element = ObjectField
    public typealias Index = Int

    private let storage: [ObjectField]

    public init(
        _ sourceFields: [ObjectField]
    ) throws(ObjectValueError) {
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
            self.storage = sourceFields
        } else {
            self.storage = sourceFields.sorted {
                $0.number < $1.number
            }
        }
    }

    /// The canonical fields in ascending number order.
    public var fields: [ObjectField] { storage }

    public var startIndex: Int { storage.startIndex }
    public var endIndex: Int { storage.endIndex }

    public subscript(position: Int) -> ObjectField {
        storage[position]
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let sharedCount = Swift.min(lhs.count, rhs.count)
        for offset in 0..<sharedCount {
            let left = lhs.storage[offset]
            let right = rhs.storage[offset]
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
