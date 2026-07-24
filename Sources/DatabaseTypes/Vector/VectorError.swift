public enum VectorError: Error, Sendable, Equatable {
    case nonFiniteFloat32(index: Int)
    case nonFiniteFloat64(index: Int)
}
