extension EntityIdentity: Hashable {
    public static func == (
        left: EntityIdentity,
        right: EntityIdentity
    ) -> Bool {
        StringIdentity.equal(left.entity, right.entity)
            && left.id == right.id
            && left.partitions == right.partitions
    }

    public func hash(into hasher: inout Hasher) {
        StringIdentity.hash(entity, into: &hasher)
        hasher.combine(id)
        hasher.combine(partitions)
    }
}
