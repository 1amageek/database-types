public enum FieldObjectError: Error, Sendable {
    case duplicateKey(String)
}

extension FieldObjectError: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.duplicateKey(let left), .duplicateKey(let right)):
            return StringIdentity.equal(left, right)
        }
    }
}
