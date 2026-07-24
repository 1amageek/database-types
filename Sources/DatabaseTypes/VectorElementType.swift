/// The scalar representation preserved by a vector value.
public enum VectorElementType: UInt8, Sendable, Hashable, Comparable {
    case float32
    case float64

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
