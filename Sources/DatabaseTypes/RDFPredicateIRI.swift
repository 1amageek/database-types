public struct RDFPredicateIRI: Sendable, Hashable, Comparable {
    public let iri: RDFIRI

    public init(_ rawValue: String) throws(RDFIRIError) {
        iri = try RDFIRI(rawValue)
    }

    public init(_ iri: RDFIRI) {
        self.iri = iri
    }

    public var rawValue: String { iri.rawValue }

    public var term: RDFTerm {
        .iri(iri)
    }

    public static func < (
        lhs: RDFPredicateIRI,
        rhs: RDFPredicateIRI
    ) -> Bool {
        lhs.iri < rhs.iri
    }
}
