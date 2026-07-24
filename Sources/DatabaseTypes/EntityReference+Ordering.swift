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

        let sharedCount = min(lhs.partitions.count, rhs.partitions.count)
        for index in 0..<sharedCount {
            if lhs.partitions[index] == rhs.partitions[index] {
                continue
            }
            return lhs.partitions[index] < rhs.partitions[index]
        }
        return lhs.partitions.count < rhs.partitions.count
    }
}
