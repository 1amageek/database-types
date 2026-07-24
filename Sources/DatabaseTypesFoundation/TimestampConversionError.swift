/// A failure to represent a Foundation date as a canonical timestamp.
public enum TimestampConversionError: Error, Sendable, Equatable {
    case nonFiniteDate
    case valueOutOfRange
}
