public enum TimeSpanError: Error, Sendable, Equatable {
    case invalidNanoseconds(UInt32)
}
