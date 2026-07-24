public enum FieldObjectError: Error, Sendable, Equatable {
    case duplicateFieldNumber(UInt32)
    case duplicateFieldName(String)
}
