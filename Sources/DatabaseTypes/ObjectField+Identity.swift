extension ObjectField: Hashable {
    public static func == (
        left: ObjectField,
        right: ObjectField
    ) -> Bool {
        left.number == right.number
            && StringIdentity.equal(left.name, right.name)
            && left.value == right.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(number)
        StringIdentity.hash(name, into: &hasher)
        hasher.combine(value)
    }
}
