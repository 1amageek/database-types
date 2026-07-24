extension ReferenceIdentifier: Hashable {
    public static func == (
        left: ReferenceIdentifier,
        right: ReferenceIdentifier
    ) -> Bool {
        StructuralComparison.equal(.identifier(left), .identifier(right))
    }

    public func hash(into hasher: inout Hasher) {
        StructuralComparison.hash(.identifier(self), into: &hasher)
    }
}
