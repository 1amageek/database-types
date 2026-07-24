public enum CivilTimeError: Error, Sendable, Equatable {
    case invalidHour(UInt8)
    case invalidMinute(UInt8)
    case invalidSecond(UInt8)
    case invalidNanoseconds(UInt32)
}
