/// The scalar representation preserved by a vector value.
public enum VectorElementType: UInt8, Sendable, Hashable, Comparable {
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
        lhs.rawValue < rhs.rawValue
    }
}
