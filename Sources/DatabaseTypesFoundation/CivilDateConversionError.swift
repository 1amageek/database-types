import DatabaseTypes

/// A failure to derive a canonical civil date from a Foundation date.
public enum CivilDateConversionError: Error, Sendable, Equatable {
    case unsupportedCalendar
    case missingDateComponents
    case yearOutOfRange(Int)
    case invalidDate(CivilDateError)
}
