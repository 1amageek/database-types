public indirect enum RDFTerm: Sendable, Hashable, Comparable {
    case iri(RDFIRI)
    case blankNode(RDFBlankNodeIdentifier)
    case literal(RDFLiteral)
    case tripleTerm(
        subject: RDFSubject,
        predicate: RDFPredicateIRI,
        object: RDFTerm
    )
}

extension RDFTerm {
    // Comparison, hashing, and ordering route through the shared iterative
    // engine so a deeply nested triple term cannot overflow the stack.
    public static func == (
        lhs: RDFTerm,
        rhs: RDFTerm
    ) -> Bool {
        StructuralComparison.equal(.term(lhs), .term(rhs))
    }

    public func hash(into hasher: inout Hasher) {
        StructuralComparison.hash(.term(self), into: &hasher)
    }

    public static func < (lhs: RDFTerm, rhs: RDFTerm) -> Bool {
        StructuralComparison.compare(.term(lhs), .term(rhs)) < 0
    }
}
