public struct EntityIdentity: Sendable {
    public let entity: String
    public let id: IdentifierValue
    public let partitions: [ObjectField]

    public init(
        entity: String,
        id: IdentifierValue,
        partitions: [ObjectField] = [],
        identifierLimits: IdentifierLimits = .default
    ) throws(EntityIdentityError) {
        guard !entity.isEmpty else {
            throw .emptyEntity
        }
        do {
            try id.validate(limits: identifierLimits)
        } catch let error {
            throw .invalidIdentifier(error)
        }
        self.entity = entity
        self.id = id
        self.partitions = partitions
    }
}
