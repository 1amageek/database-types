public enum EntityReferenceError: Error, Sendable, Equatable {
    case emptyEntity
    case invalidIdentifier(ReferenceIdentifierValidationError)
}
