public enum CivilDateError: Error, Sendable, Equatable {
    case invalidMonth(UInt8)
    case invalidDay(
        UInt8,
        year: Int32,
        month: UInt8,
        maximum: UInt8
    )
}
