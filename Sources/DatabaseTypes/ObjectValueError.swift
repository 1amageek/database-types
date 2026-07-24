public enum ObjectValueError: Error, Sendable, Equatable {
    case duplicateFieldNumber(UInt32)
    case duplicateFieldName(String)
}
