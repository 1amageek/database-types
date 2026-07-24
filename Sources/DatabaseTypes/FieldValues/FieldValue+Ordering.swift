extension FieldValue: Comparable {
    public static func < (lhs: FieldValue, rhs: FieldValue) -> Bool {
        StructuralComparison.compare(.field(lhs), .field(rhs)) < 0
    }
}
