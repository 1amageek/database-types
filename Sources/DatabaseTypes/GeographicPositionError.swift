public enum GeographicPositionError: Error, Sendable, Equatable {
    case invalidPoint(GeographicPointError)
    case nonFiniteEllipsoidalHeight
}
