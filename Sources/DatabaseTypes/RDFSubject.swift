/// A term that may occupy the subject position of an RDF triple.
public enum RDFSubject: Sendable, Hashable, Comparable,
    CustomStringConvertible {
    case iri(RDFIRI)
    case blankNode(RDFBlankNodeIdentifier)

    public var term: RDFTerm {
        switch self {
        case .iri(let iri):
            return .iri(iri)
        case .blankNode(let identifier):
            return .blankNode(identifier)
        }
    }

    public static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        switch (lhs, rhs) {
        case (.iri(let left), .iri(let right)):
            return left < right
        case (.blankNode(let left), .blankNode(let right)):
            return left < right
        case (.blankNode, .iri):
            return true
        case (.iri, .blankNode):
            return false
        }
    }

    public var description: String { term.description }
}
