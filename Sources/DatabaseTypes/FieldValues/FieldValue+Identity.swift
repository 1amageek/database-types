extension FieldValue: Hashable {
    public static func == (left: FieldValue, right: FieldValue) -> Bool {
        StructuralComparison.equal(.field(left), .field(right))
    }

    public func hash(into hasher: inout Hasher) {
        StructuralComparison.hash(.field(self), into: &hasher)
    }
}
