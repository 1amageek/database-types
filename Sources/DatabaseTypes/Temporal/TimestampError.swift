public enum TimestampError: Error, Sendable, Equatable {
    case invalidNanoseconds(UInt32)
}
