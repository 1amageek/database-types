/// A failure to convert a Foundation date-component amount.
public enum CalendarPeriodConversionError: Error, Sendable, Equatable {
    case unsupportedComponent
    case valueOutOfRange
    case monthOverflow
}
