extension IdentifierValue: Comparable {
    public static func < (
        lhs: IdentifierValue,
        rhs: IdentifierValue
    ) -> Bool {
        let lhsRank = rank(of: lhs)
        let rhsRank = rank(of: rhs)
        guard lhsRank == rhsRank else {
            return lhsRank < rhsRank
        }
        switch (lhs, rhs) {
        case (.bool(let left), .bool(let right)):
            return !left && right
        case (.int8(let left), .int8(let right)):
            return left < right
        case (.int16(let left), .int16(let right)):
            return left < right
        case (.int32(let left), .int32(let right)):
            return left < right
        case (.int64(let left), .int64(let right)):
            return left < right
        case (.uint8(let left), .uint8(let right)):
            return left < right
        case (.uint16(let left), .uint16(let right)):
            return left < right
        case (.uint32(let left), .uint32(let right)):
            return left < right
        case (.uint64(let left), .uint64(let right)):
            return left < right
        case (.string(let left), .string(let right)):
            return StringIdentity.less(left, right)
        case (.bytes(let left), .bytes(let right)):
            return left < right
        case (.uuid(let left), .uuid(let right)):
            return left < right
        case (.composite(let left), .composite(let right)):
            let sharedCount = min(left.count, right.count)
            for index in 0..<sharedCount {
                if left[index] == right[index] {
                    continue
                }
                return left[index] < right[index]
            }
            return left.count < right.count
        default:
            return false
        }
    }

    private static func rank(
        of value: IdentifierValue
    ) -> UInt8 {
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
}
