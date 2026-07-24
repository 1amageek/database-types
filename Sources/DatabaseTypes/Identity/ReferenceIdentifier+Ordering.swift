extension ReferenceIdentifier: Comparable {
    public static func < (
        lhs: ReferenceIdentifier,
        rhs: ReferenceIdentifier
    ) -> Bool {
        StructuralComparison.compare(.identifier(lhs), .identifier(rhs)) < 0
    }
}
