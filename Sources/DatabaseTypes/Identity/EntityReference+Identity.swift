extension EntityReference: Hashable {
    // Routed through the shared iterative engine so that a reference whose
    // partitions nest further references cannot overflow the stack, and so a
    // reference compares identically whether standalone or inside
    // `FieldValue.reference`.
    public static func == (
        left: EntityReference,
        right: EntityReference
    ) -> Bool {
        StructuralComparison.equal(.field(.reference(left)), .field(.reference(right)))
    }

    public func hash(into hasher: inout Hasher) {
        StructuralComparison.hash(.field(.reference(self)), into: &hasher)
    }
}
