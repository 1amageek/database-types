extension EntityReference: Comparable {
    public static func < (
        lhs: EntityReference,
        rhs: EntityReference
    ) -> Bool {
        StructuralComparison.compare(.field(.reference(lhs)), .field(.reference(rhs))) < 0
    }
}
