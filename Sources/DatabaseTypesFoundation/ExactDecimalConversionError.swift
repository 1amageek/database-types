/// A failure to convert between Foundation and canonical decimal values.
public enum ExactDecimalConversionError: Error, Sendable, Equatable {
    case nonFiniteValue
    case invalidRepresentation
    case coefficientOutOfRange
    case scaleOutOfRange
    case valueOutOfRange
}
