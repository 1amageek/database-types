public enum ExactDecimalError: Error, Sendable, Equatable {
    case numericOverflow
    case divisionByZero
    case inexactResult
}
