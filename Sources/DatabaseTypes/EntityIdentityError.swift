public enum EntityIdentityError: Error, Sendable, Equatable {
    case emptyEntity
    case invalidIdentifier(IdentifierValidationError)
}
