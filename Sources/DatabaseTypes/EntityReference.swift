/// A self-contained primitive reference to an entity value.
///
/// Model identity declaration and reference resolution belong to upper layers.
/// This type only preserves the reference's canonical value and invariants.
public struct EntityReference: Sendable {
    public let entity: String
    public let id: ReferenceIdentifier
    public let partitions: [ObjectField]

    public init(
        entity: String,
        id: ReferenceIdentifier,
        partitions: [ObjectField] = []
    ) throws(EntityReferenceError) {
        guard !entity.isEmpty else {
            throw .emptyEntity
        }
        do {
            try id.validate()
        } catch let error {
            throw .invalidIdentifier(error)
        }
        self.entity = entity
        self.id = id
        self.partitions = partitions
    }
}
