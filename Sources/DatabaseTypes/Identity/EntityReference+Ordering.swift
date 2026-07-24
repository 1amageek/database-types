extension EntityReference: Comparable {
    public static func < (
        lhs: EntityReference,
        rhs: EntityReference
    ) -> Bool {
        if !StringIdentity.equal(lhs.entity, rhs.entity) {
            return StringIdentity.less(lhs.entity, rhs.entity)
        }
        if lhs.id != rhs.id {
            return lhs.id < rhs.id
        }
        return lhs.partitions < rhs.partitions
    }
}
