extension ObjectField: Comparable {
    public static func < (
        lhs: ObjectField,
        rhs: ObjectField
    ) -> Bool {
        if lhs.number != rhs.number {
            return lhs.number < rhs.number
        }
        if !StringIdentity.equal(lhs.name, rhs.name) {
            return StringIdentity.less(lhs.name, rhs.name)
        }
        return lhs.value < rhs.value
    }
}
