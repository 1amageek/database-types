/// Validates identifier values with a bounded, iterative walk.
extension IdentifierValue {
    public func validate(
        limits: IdentifierLimits = .default
    ) throws(IdentifierValidationError) {
        var pending: [(value: IdentifierValue, depth: Int)] = [(self, 0)]
        var componentCount = 0

        while let node = pending.popLast() {
            componentCount = try Self.checkedComponentCount(
                after: componentCount,
                limits: limits
            )
            guard case .composite(let components) = node.value else {
                continue
            }
            guard !components.isEmpty else {
                throw .emptyComposite
            }
            guard node.depth < limits.maximumCompositeDepth else {
                throw .compositeDepthExceeded(
                    actual: node.depth + 1,
                    maximum: limits.maximumCompositeDepth
                )
            }
            try Self.validateScheduledComponentCount(
                components.count,
                currentCount: componentCount,
                limits: limits
            )
            for component in components.reversed() {
                pending.append((component, node.depth + 1))
            }
        }
    }

    private static func checkedComponentCount(
        after componentCount: Int,
        limits: IdentifierLimits
    ) throws(IdentifierValidationError) -> Int {
        let (nextCount, overflow) = componentCount.addingReportingOverflow(1)
        guard !overflow, nextCount <= limits.maximumComponentCount else {
            throw .componentCountExceeded(
                actual: overflow ? Int.max : nextCount,
                maximum: limits.maximumComponentCount
            )
        }
        return nextCount
    }

    private static func validateScheduledComponentCount(
        _ scheduledCount: Int,
        currentCount: Int,
        limits: IdentifierLimits
    ) throws(IdentifierValidationError) {
        let (total, overflow) = currentCount.addingReportingOverflow(
            scheduledCount
        )
        guard !overflow, total <= limits.maximumComponentCount else {
            throw .componentCountExceeded(
                actual: overflow ? Int.max : total,
                maximum: limits.maximumComponentCount
            )
        }
    }
}
