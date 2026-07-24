/// Validates intrinsic identifier invariants with an iterative walk.
extension ReferenceIdentifier {
    public func validate() throws(ReferenceIdentifierValidationError) {
        var pending: [ReferenceIdentifier] = [self]

        while let value = pending.popLast() {
            guard case .composite(let components) = value else {
                continue
            }
            guard !components.isEmpty else {
                throw .emptyComposite
            }
            for component in components.reversed() {
                pending.append(component)
            }
        }
    }
}
