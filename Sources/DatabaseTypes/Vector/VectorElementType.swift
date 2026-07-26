/// The scalar representation preserved by a vector value.
public enum VectorElementType: Sendable, Hashable, Comparable {
    case int8
    case int16
    case int32
    case int64
    case uint8
    case uint16
    case uint32
    case uint64
    case float32
    case float64

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.comparisonRank < rhs.comparisonRank
    }

    var byteCount: Int {
        switch self {
        case .int8, .uint8:
            return 1
        case .int16, .uint16:
            return 2
        case .int32, .uint32, .float32:
            return 4
        case .int64, .uint64, .float64:
            return 8
        }
    }

    private var comparisonRank: UInt8 {
        switch self {
        case .int8: 0
        case .int16: 1
        case .int32: 2
        case .int64: 3
        case .uint8: 4
        case .uint16: 5
        case .uint32: 6
        case .uint64: 7
        case .float32: 8
        case .float64: 9
        }
    }
}
