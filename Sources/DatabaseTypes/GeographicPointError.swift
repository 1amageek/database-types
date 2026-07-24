public enum GeographicPointError: Error, Sendable, Equatable {
    case nonFiniteLatitude
    case nonFiniteLongitude
    case latitudeOutOfRange(Double)
    case longitudeOutOfRange(Double)
}
