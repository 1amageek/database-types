extension FieldValue: Comparable {
    public static func < (lhs: FieldValue, rhs: FieldValue) -> Bool {
        let lhsRank = rank(of: lhs)
        let rhsRank = rank(of: rhs)
        guard lhsRank == rhsRank else {
            return lhsRank < rhsRank
        }

        switch (lhs, rhs) {
        case (.null, .null):
            return false
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
        case (.float32(let left), .float32(let right)):
            return left.isTotallyOrdered(belowOrEqualTo: right)
                && left.bitPattern != right.bitPattern
        case (.float64(let left), .float64(let right)):
            return left.isTotallyOrdered(belowOrEqualTo: right)
                && left.bitPattern != right.bitPattern
        case (.decimal(let left), .decimal(let right)):
            return left < right
        case (.string(let left), .string(let right)):
            return StringIdentity.less(left, right)
        case (.bytes(let left), .bytes(let right)):
            return left.lexicographicallyPrecedes(right)
        case (.date(let left), .date(let right)):
            return left < right
        case (.time(let left), .time(let right)):
            return left < right
        case (.dateTime(let left), .dateTime(let right)):
            return left < right
        case (.timestamp(let left), .timestamp(let right)):
            return left < right
        case (.timeSpan(let left), .timeSpan(let right)):
            return left < right
        case (.calendarPeriod(let left), .calendarPeriod(let right)):
            return left < right
        case (.geographicPoint(let left), .geographicPoint(let right)):
            return left < right
        case (
            .geographicPosition(let left),
            .geographicPosition(let right)
        ):
            return left < right
        case (.vector(let left), .vector(let right)):
            return left < right
        case (.uuid(let left), .uuid(let right)):
            return left < right
        case (.array(let left), .array(let right)):
            return lexicographicallyPrecedes(left, right)
        case (.object(let left), .object(let right)):
            return left < right
        case (.reference(let left), .reference(let right)):
            return left < right
        case (.rdfTerm(let left), .rdfTerm(let right)):
            return left < right
        default:
            return false
        }
    }

    private static func rank(of value: FieldValue) -> UInt8 {
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

    private static func lexicographicallyPrecedes(
        _ left: [FieldValue],
        _ right: [FieldValue]
    ) -> Bool {
        let sharedCount = min(left.count, right.count)
        for index in 0..<sharedCount {
            if left[index] == right[index] {
                continue
            }
            return left[index] < right[index]
        }
        return left.count < right.count
    }

}
